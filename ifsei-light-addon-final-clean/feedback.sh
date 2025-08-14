#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Feedback Bruto "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

# 1️⃣ Ativa MON6
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

# 2️⃣ Coleta e publica feedbacks sem filtrar conteúdo
echo "📡 Coletando feedback bruto..."

while true; do
  nc "$IP" "$PORT" | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"

    # Tenta extrair o endereço do módulo (xx) da string *Dxx...
    if [[ "$line" =~ ^\*D([0-9]{2}) ]]; then
      MOD="${BASH_REMATCH[1]}"
      ENTITY="input_text.ifsei_mod${MOD}_feedback"

      echo "📤 Publicando feedback bruto em $ENTITY"
      curl -s -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{{\"state\": \"$line\"}}" \
        http://supervisor/core/api/states/$ENTITY > /dev/null
    fi
  done

  echo "⚠️ Conexão encerrada. Reconectando em 2s..."
  sleep 2
done
