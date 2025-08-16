#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"
PID_FILE="/tmp/listener.pid"

echo "[INFO] Iniciando listener de feedback em $IP:$PORT..."
echo $$ > "$PID_FILE"  # Guarda o PID do próprio processo

while true; do
  echo "[INFO] Conectando..."
  nc "$IP" "$PORT" | tee -a "$LOG_FILE"
  echo "[WARN] Conexão perdida. Tentando reconectar..."
  sleep 0.2
done
