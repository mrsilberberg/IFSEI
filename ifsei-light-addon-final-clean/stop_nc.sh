#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/tmp/listener.pid"

if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Encerrando listener (PID $PID)..."
    kill -9 "$PID" || true
  else
    echo "[WARN] PID $PID não está rodando."
  fi
  rm -f "$PID_FILE"
else
  echo "[WARN] Nenhum listener ativo encontrado."
fi
