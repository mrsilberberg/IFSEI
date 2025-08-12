#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"
POLL_INTERVAL=$(jq -r '."poll-interval" // 5' "$CONFIG")

readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

echo "📡 Polling IFSEI em $IP:$PORT"
echo "⏱  Intervalo: ${POLL_INTERVAL}s"
echo "📄 Log: $LOG_FILE"
: > "$LOG_FILE"

while true; do
  for MOD in "${MODULES[@]}"; do
    CMD="\$D${MOD}ST\r"
    echo "➡️  Enviando: $CMD"

    # Envia o comando e extrai apenas o bloco útil
    (echo -ne "$CMD"; sleep 0.5) | nc -w0.5 "$IP" "$PORT" \
    | tr '\r' '\n' \
    | grep -o "D${MOD}C[0-9][0-9]Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}" \
    | while read -r status; do
        echo "$(date '+%F %T') - Mod $MOD - $status" | tee -a "$LOG_FILE"
      done

    sleep 0.2
  done

  sleep "$POLL_INTERVAL"
done
