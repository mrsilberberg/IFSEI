#!/usr/bin/env bash

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

# Adiciona parâmetro ajustável para intervalo (em segundos)
POLL_INTERVAL=$(jq -r '."poll-interval" // 5' "$CONFIG")

readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

echo "📡 Monitorando IFSEI em $IP:$PORT"
echo "⏱  Intervalo de polling: ${POLL_INTERVAL}s"
echo "📄 Log: $LOG_FILE"
: > "$LOG_FILE"

# Thread 1: leitura contínua de qualquer mensagem enviada pelo gateway
{
  while true; do
    nc $IP $PORT | while read -r line; do
      if [ -n "$line" ]; then
        echo "$(date '+%F %T') - RX: $line" | tee -a "$LOG_FILE"
      fi
    done
    echo "⚠️ Conexão perdida, tentando reconectar..."
    sleep 1
  done
} &

# Thread 2: polling cíclico de status de cada módulo
while true; do
  for MOD in "${MODULES[@]}"; do
    CMD="\$D${MOD}ST\r"
    echo "➡️  [Polling] Enviando: $CMD"
    echo -ne "$CMD" | nc -w1 $IP $PORT | while read -r resp; do
      if [ -n "$resp" ]; then
        echo "$(date '+%F %T') - Mod $MOD - $resp" | tee -a "$LOG_FILE"
      fi
    done
    sleep 0.3
  done
  sleep "$POLL_INTERVAL"
done
