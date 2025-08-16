#!/usr/bin/env bash
set -e

echo "[INFO] Gerando arquivos YAML..."
/generate.sh
echo "[INFO] Arquivos gerados."

echo "[INFO] Iniciando listener de feedback..."
/listener.sh &

echo "[INFO] Iniciando parser de feedback..."
/parser.sh
