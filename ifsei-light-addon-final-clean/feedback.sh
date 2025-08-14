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

LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Feedback via MQTT "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "MQTT: $MQTT_USER@$MQTT_HOST:$MQTT_PORT"
echo "Log: $LOG_FILE"
echo "=============================="

# Ativa MON6
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.5

# Loop de escuta e publicação MQTT
while true; do
  nc "$IP" "$PORT" | tee -a "$LOG_FILE" | while read -r line; do
    if [[ "$line" =~ ^\*?D([0-9]{2}) ]]; then
      MOD="${BASH_REMATCH[1]}"
      TOPIC="$TOPIC_PREFIX/mod${MOD}/feedback"
      echo "📤 MQTT → $TOPIC: $line"
      mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" -t "$TOPIC" -m "$line"
    fi
  done

  echo "⚠️ Conexão encerrada. Reabrindo em 2s..."
  sleep 2
done
