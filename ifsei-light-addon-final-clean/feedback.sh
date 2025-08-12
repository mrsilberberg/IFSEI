#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "📡 Monitoramento IFSEI em $IP:$PORT usando MON6"
: > "$LOG_FILE"

while true; do
    echo "🔄 Conectando..."
    
    {
        # Ativa o nível de monitoramento 6
        echo -ne "\$MON6\r"
        sleep 0.1

        # Mantém a conexão aberta
        while read -r line; do
            # Remove \r e imprime no log
            clean_line=$(echo "$line" | tr -d '\r')
            if [ -n "$clean_line" ]; then
                echo "$(date '+%F %T') - $clean_line" | tee -a "$LOG_FILE"
            fi
        done
    } | nc "$IP" "$PORT"

    echo "⚠️ Conexão perdida. Tentando reconectar em 2 segundos..."
    sleep 2
done
