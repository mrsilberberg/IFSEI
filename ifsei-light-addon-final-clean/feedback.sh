#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Feedback Ativo "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

echo "📡 Iniciando sessão de monitoramento..."

while true; do
  (
    # Aguarda conexão e ativa MON6 após 1s
    sleep 1
    echo -ne '$MON6
'
    sleep 1
    cat
  ) | nc "$IP" "$PORT" | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"

    # Extrai endereço do módulo (ex: *D00...)
    if [[ "$line" =~ ^\*?D([0-9]{2}) ]]; then
      MOD="${BASH_REMATCH[1]}"
      ENTITY="input_text.ifsei_mod${MOD}_feedback"

      echo "📤 Publicando em $ENTITY: $line"
      curl -s -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{{\"state\": \"$line\"}}" \
        http://supervisor/core/api/states/$ENTITY > /dev/null
    fi
  done

  echo "⚠️ Conexão encerrada. Reabrindo em 2s..."
  sleep 2
done
