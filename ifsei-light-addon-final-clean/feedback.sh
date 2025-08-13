#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

echo "📡 Iniciando listener passivo (capturando C00)..."

while true; do
    nc "$IP" "$PORT" \
    | tr -d '\r' \
    | while read -r line; do
        # Remove caracteres iniciais e verifica se contém C00
        clean=$(echo "$line" | sed -E 's/^>?\*?//')
        case "$clean" in
            D??C00Z*)
                echo "$clean" > "$LOG_FILE"
                ;;
        esac
    done
    echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
    sleep 2
done
