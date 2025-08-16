#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")

MOD="$1"
ZONE="$2"
BRIGHTNESS="$3"

PID_FILE="/tmp/listener.pid"

# Converte brightness (0-255) para escala IFSEI (00–63)
LEVEL=$(printf "%02d" $(( BRIGHTNESS * 63 / 255 )))

CMD="\$D${MOD}Z${ZONE}${LEVEL}T0\r"

echo "[INFO] Preparando para enviar comando: $CMD"

# 1. Para listener atual
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Encerrando listener (PID $PID)..."
    kill -9 "$PID" || true
  fi
  rm -f "$PID_FILE"
fi

# 2. Envia comando
echo -ne "$CMD" | nc -w1 "$IP" "$PORT"
sleep 0.05
echo -ne "$CMD" | nc -w1 "$IP" "$PORT"

echo "[INFO] Comando enviado para $IP:$PORT → $CMD"
echo "[INFO] Listener irá reconectar automaticamente..."
