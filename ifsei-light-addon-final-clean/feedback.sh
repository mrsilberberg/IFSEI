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

# 1️⃣ Ativa MON6 (modo detalhado)
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

# 2️⃣ Escuta passiva com reconexão e publicação
echo "📡 Iniciando listener passivo..."

while true; do
  nc "$IP" "$PORT" | while read -r line; do
    echo "$line" | tee -a "$LOG_FILE"

    # Exemplo esperado: *D01C15Z800Z700Z600Z500Z400Z300Z200Z100
    if [[ "$line" =~ ^\*D([0-9]{2})C[0-9]{2}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3}Z[0-9]{3} ]]; then
      MOD="${BASH_REMATCH[1]}"
      ENTITY="input_text.ifsei_mod${MOD}_feedback"

      echo "📤 Atualizando $ENTITY com: $line"
      curl -s -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{{\"state\": \"$line\"}}" \
        http://supervisor/core/api/states/$ENTITY > /dev/null
    fi
  done

  echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
  sleep 2
done
