#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"

IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
MQTT_HOST=$(jq -r .mqtt_host "$CONFIG")
MQTT_PORT=$(jq -r .mqtt_port "$CONFIG")
MQTT_USER=$(jq -r .mqtt_username "$CONFIG")
MQTT_PASS=$(jq -r .mqtt_password "$CONFIG")
TOPIC_PREFIX=$(jq -r .mqtt_topic_prefix "$CONFIG")
LAST_LINE=""

LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Feedback via MQTT (penúltima linha) "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "MQTT: $MQTT_USER@$MQTT_HOST:$MQTT_PORT"
echo "Log: $LOG_FILE"
echo "=============================="

echo "🔎 Testando conexão MQTT..."
if ! mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
  -t "$TOPIC_PREFIX/test" -m "IFSEI MQTT connected at $(date)"; then
  echo "❌ Erro: Falha ao conectar ao broker MQTT!"
  exit 1
fi
echo "✅ Conexão MQTT bem-sucedida!"

# Ativa MON6
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.5

# Loop principal
while true; do
  # Captura pacotes recebidos e armazena no log
  nc -w1 "$IP" "$PORT" >> "$LOG_FILE"

  # Pega a penúltima linha válida (*Dxx) ignorando IFSEION
  penultima=$(grep -o '\*D[0-9]\{2\}[^ >]*' "$LOG_FILE" \
              | grep -v '\*IFSEION' \
              | tail -n 2 | head -n 1)

  # Publica apenas se for nova
  if [[ -n "$penultima" && "$penultima" != "$LAST_LINE" ]]; then
    MOD=$(echo "$penultima" | sed -n 's/\*D\([0-9]\{2\}\).*/\1/p')
    TOPIC="$TOPIC_PREFIX/mod${MOD}/feedback"
    echo "📤 MQTT → $TOPIC: $penultima"
    mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" \
      -u "$MQTT_USER" -P "$MQTT_PASS" \
      -t "$TOPIC" -m "$penultima"
    LAST_LINE="$penultima"
  fi

  # Pequena pausa antes de reconectar
  sleep 0.05
done
