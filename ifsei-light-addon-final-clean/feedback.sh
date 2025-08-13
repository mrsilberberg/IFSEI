#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

echo "📡 Escutando apenas C00 (sobrescrevendo arquivo a cada atualização)..."

while true; do
    nc "$IP" "$PORT" \
    | tr -d '\r' \
    | grep -o "D[0-9][0-9]C00[Zz][0-9]\{3\}\([Zz][0-9]\{3\}\)\{7\}" \
    | while read -r status; do
        echo "$(date '+%F %T') - $status" | tee "$LOG_FILE"
      done
    echo "⚠️ Conexão encerrada. Reabrindo em 2s..."
    sleep 2
done
