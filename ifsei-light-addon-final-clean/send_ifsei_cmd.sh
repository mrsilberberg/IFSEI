#!/usr/bin/env bash
set -euo pipefail

# Args vindos do HA
MOD="$1"
ZONE="$2"
BRIGHTNESS="$3"

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")

# Script listener que precisa ser reiniciado
LISTENER="/listener.sh"

# Calcula valor (0–63) a partir do brilho (0–255)
LEVEL=$(printf "%02d" $(( BRIGHTNESS * 63 / 255 )))

echo "[INFO] Enviando comando IFSEI → Mód:$MOD Zona:$ZONE Nível:$LEVEL"

# 1. Derruba netcats antigos (listener usa nc em loop)
killall nc 2>/dev/null || true
sleep 0.05
killall nc 2>/dev/null || true
sleep 0.05

# 2. Envia o comando para o módulo
echo -ne "\$D${MOD}Z${ZONE}${LEVEL}T0\r" | nc -w1 "$IP" "$PORT"
sleep 0.05
echo -ne "\$D${MOD}Z${ZONE}${LEVEL}T0\r" | nc -w1 "$IP" "$PORT"

# 3. Reinicia listener em background
if pgrep -f "$LISTENER" >/dev/null; then
  echo "[INFO] Listener já em execução."
else
  echo "[INFO] Reiniciando listener..."
  nohup "$LISTENER" >/dev/null 2>&1 &
fi

echo "[INFO] Comando enviado e listener garantido em execução."
