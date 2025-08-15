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

# Carrega lista de módulos do options.json
readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

echo "=============================="
echo "  IFSEI Add-on - Feedback via MQTT (penúltima linha) "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "MQTT: $MQTT_USER@$MQTT_HOST:$MQTT_PORT"
echo "Log: $LOG_FILE"
echo "Módulos: ${MODULES[*]}"
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
  # Publica apenas se for nova
  if [[ -n "$penultima" && "$penultima" != "$LAST_LINE" ]]; then
    LAST_LINE="$penultima"
    echo "[EVENTO NOVO DETECTADO] $penultima"

    for MOD_REQ in "${MODULES[@]}"; do
      echo "📡 Solicitando status do módulo $MOD_REQ"
      resposta=$(echo -ne "\$D${MOD_REQ}ST\r" | nc -w1 "$IP" "$PORT" \
                 | grep -o '\*D[0-9].*' | grep -v '\*IFSEION')

      if [[ -n "$resposta" ]]; then
        echo "[STATUS M${MOD_REQ}] $resposta"
        echo "$resposta" >> "$LOG_FILE"

        # Atualiza entidade de feedback no Home Assistant
        ha entity update "input_text.ifsei_mod${MOD_REQ}_feedback" --value "$resposta" || true
      else
        echo "[AVISO] Nenhum retorno para módulo $MOD_REQ"
      fi

      sleep 0.05
    done
  fi

  sleep 0.05
done
