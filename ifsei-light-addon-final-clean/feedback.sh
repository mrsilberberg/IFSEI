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

    # Envia o comando e lê a resposta
    echo -ne "$CMD" | nc -w2 $IP $PORT | while read -r line; do
      if [ -n "$line" ]; then
        echo "$(date '+%F %T') - Mod $MOD - $line" | tee -a "$LOG_FILE"
      fi
    done

    sleep 0.3
  done

  sleep "$POLL_INTERVAL"
done
