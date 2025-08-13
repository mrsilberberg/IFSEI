#!/usr/bin/env bash
set -euo pipefail

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

# 2️⃣ Inicia listener passivo (apenas C00, sobrescrevendo)
echo "📡 Iniciando listener passivo (apenas C00, sobrescrevendo)..."

while true; do
    nc "$IP" "$PORT" | grep -o "\*D[0-9][0-9]C00Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}Z[0-9]\{3\}" |
    while read -r linha; do
        echo "$linha" > "$LOG_FILE"
    done
    echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
    sleep 2
done
