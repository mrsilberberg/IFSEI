#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Listener - Captura contínua"
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

while true; do
  echo "[INFO] Conectando ao IFSEI para captura..."
  nc "$IP" "$PORT" | tee -a "$LOG_FILE"
  echo "[WARN] Conexão perdida. Tentando reconectar..."
  sleep 1
done
