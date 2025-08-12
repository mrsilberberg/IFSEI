#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
FIFO="/tmp/ifsei_fifo"
LOG_FEEDBACK="/config/ifsei_realtime.log"
LOG_SENT="/config/ifsei_sent.log"

echo "📡 Iniciando daemon IFSEI (conexão TCP bidirecional)"
echo "📍 Conectando em: $IP:$PORT"
echo "📂 FIFO: $FIFO"
echo "📄 Log feedback: $LOG_FEEDBACK"
echo "📄 Log enviado: $LOG_SENT"
: > "$LOG_FEEDBACK"
: > "$LOG_SENT"

# Cria o FIFO se não existir
[ -p "$FIFO" ] || mkfifo "$FIFO"

# Conexão TCP contínua - escuta e extrai feedbacks em tempo real
{
  while true; do
    echo "📥 Aguardando dados em tempo real de $IP:$PORT..."
    nc -v "$IP" "$PORT" < "$FIFO" | tr '\r' '\n' \
    | grep -o "D[0-9][0-9]C[0-9][0-9]Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}Z[0-9]\\{3\\}" \
    | while read -r status; do
        echo "$(date '+%F %T') - EVENT - $status" | tee -a "$LOG_FEEDBACK"
      done
    echo "⚠️ Conexão encerrada. Reconectando..."
    sleep 1
  done
} &

# Thread que monitora e envia comandos via FIFO
while true; do
  if read -r CMD < "$FIFO"; then
    echo "$(date '+%F %T') - TX - $CMD" | tee -a "$LOG_SENT"
    echo -ne "$CMD" > "$FIFO"
  fi
done

