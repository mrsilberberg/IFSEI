#!/usr/bin/env bash
PID_FILE="/tmp/listener.pid"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Encerrando listener PID $PID..."
    kill -9 "$PID"
    rm -f "$PID_FILE"
  else
    echo "[WARN] Listener já não está ativo."
    rm -f "$PID_FILE"
  fi
else
  echo "[WARN] Nenhum listener PID encontrado."
fi
