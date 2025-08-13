#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Modo Feedback "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

# 1️⃣ Ativa MON6 (uma vez)
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

# 2️⃣ Inicia listener passivo com filtro C00
echo "📡 Iniciando listener passivo (filtrando para C00)..."

while true; do
    nc "$IP" "$PORT" \
    | tr -d '\r' \
    | while read -r line; do
        # Remove > e * do início, e filtra apenas C00 com 8 zonas
        if [[ "$line" =~ ^\>*\**(D[0-9]{2}C00Z[0-9]{3}(Z[0-9]{3}){7})$ ]]; then
            echo "${BASH_REMATCH[1]}" > "$LOG_FILE"
        fi
    done
    echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
    sleep 2
done
