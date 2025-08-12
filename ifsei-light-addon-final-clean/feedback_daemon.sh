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

# Abre conexão TCP bidirecional: leitura da central e escrita via FIFO
while true; do
  echo "🔌 Abrindo conexão TCP com IFSEI..."
  nc -v "$IP" "$PORT" < "$FIFO" | while read -r line; do
    if [ -n "$line" ]; then
      echo "$(date '+%F %T') - RX - $line" | tee -a "$LOG_FEEDBACK"
    fi
  done
  echo "⚠️ Conexão encerrada, tentando reconectar em 2s..."
  sleep 2
done &

# Monitor FIFO para comandos enviados (log opcional)
while true; do
  if read -r CMD < "$FIFO"; then
    echo "$(date '+%F %T') - TX - $CMD" >> "$LOG_SENT"
    echo -ne "$CMD" > "$FIFO"
  fi
done
