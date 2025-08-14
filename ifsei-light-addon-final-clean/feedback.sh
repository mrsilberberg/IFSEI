#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Log Bruto Ativo "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

while true; do
  echo "📡 Conectando diretamente com nc (apenas log)..."
  nc "$IP" "$PORT" | tee -a "$LOG_FILE"
  echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
  sleep 2
done
