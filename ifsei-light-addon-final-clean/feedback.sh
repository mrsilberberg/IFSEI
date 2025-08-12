#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"
POLL_INTERVAL=$(jq -r '."poll-interval" // 5' "$CONFIG")

readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

FIFO="/tmp/ifsei_pipe"

echo "📡 Conexão TCP persistente com IFSEI $IP:$PORT"
echo "⏱  Intervalo de polling: ${POLL_INTERVAL}s"
echo "📄 Log: $LOG_FILE"
: > "$LOG_FILE"

# Cria FIFO se não existir
[ -p "$FIFO" ] || mkfifo "$FIFO"

# Estabelece conexão bidirecional (entrada: FIFO | saída: leitura)
# A saída é processada em tempo real
nc $IP $PORT < "$FIFO" | while read -r line; do
  if [ -n "$line" ]; then
    echo "$(date '+%F %T') - RX: $line" | tee -a "$LOG_FILE"
  fi
done &

# Função de envio de comandos via FIFO
send() {
  echo -ne "$1" > "$FIFO"
}

# Loop de polling periódico via FIFO (usando conexão já aberta)
while true; do
  for MOD in "${MODULES[@]}"; do
    CMD="\$D${MOD}ST\r"
    echo "➡️  Enviando via FIFO: $CMD"
    send "$CMD"
    sleep 0.3
  done
  sleep "$POLL_INTERVAL"
done
