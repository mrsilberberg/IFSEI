#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"
PID_FILE="/tmp/listener.pid"

echo "[INFO] Iniciando listener de feedback em $IP:$PORT..."

# Loop de reconexão
while true; do
  echo "[INFO] Conectando ao IFSEI ($IP:$PORT)..."

  # Executa o netcat em background e salva PID
  nc -w86400 "$IP" "$PORT" | tee -a "$LOG_FILE" &
  NC_PID=$!
  echo "$NC_PID" > "$PID_FILE"

  # Aguarda o netcat encerrar (bloqueia até cair a conexão)
  wait $NC_PID

  echo "[WARN] Conexão perdida. Tentando reconectar em 1s..."
  sleep 1
done
