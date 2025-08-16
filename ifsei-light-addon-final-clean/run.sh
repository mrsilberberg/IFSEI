#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Gerando arquivos YAML..."
/generate.sh
echo "[INFO] Arquivos gerados."

echo "[INFO] Iniciando listener de feedback..."
/listener.sh 2>&1 &

echo "[INFO] Iniciando parser de feedback..."
exec /parser.sh 2>&1
