#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Feedback NC Puro "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

while true; do
  echo "📡 Conectando diretamente com nc..."
  nc "$IP" "$PORT" | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"

    # Tenta extrair o módulo do feedback
    if [[ "$line" =~ ^\*?D([0-9]{2}) ]]; then
      MOD="${BASH_REMATCH[1]}"
      ENTITY="input_text.ifsei_mod${MOD}_feedback"

      echo "📤 Publicando: $line → $ENTITY"
      curl -s -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"state\": \"$line\"}" \
        http://supervisor/core/api/states/$ENTITY > /dev/null
    fi
  done

  echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
  sleep 2
done
