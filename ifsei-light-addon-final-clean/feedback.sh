#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "📡 Modo escuta passiva IFSEI em $IP:$PORT"
: > "$LOG_FILE"

while true; do
    # Conecta e só escuta
    nc "$IP" "$PORT" | while IFS= read -r line; do
        clean_line=$(echo "$line" | tr -d '\r')
        echo "$clean_line"
        echo "$(date '+%F %T') - $clean_line" >> "$LOG_FILE"
    done
    echo "⚠️ Conexão perdida. Reconectando em 2 segundos..."
    sleep 2
done
