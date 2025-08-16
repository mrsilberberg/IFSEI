#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LAST_LINE=""
LOG_FILE="/config/ifsei_feedback.log"



# Carrega lista de módulos
readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")


echo "=============================="
echo "  IFSEI Parser - Processa LOG_FILE"
echo "=============================="
echo "Módulos: ${MODULES[*]}"
echo "Log: $LOG_FILE"
echo "=============================="

while true; do
  penultima=$(grep -o '\*D[0-9]\{2\}[^ >]*' "$LOG_FILE" \
             | grep -v '\*IFSEION' \
             | tail -n 2 | head -n 1)

  if [[ -n "$penultima" && "$penultima" != "$LAST_LINE" ]]; then
    LAST_LINE="$penultima"
    echo "[EVENTO] $penultima"

    for MOD_REQ in "${MODULES[@]}"; do
      resposta=$(echo -ne "\$D${MOD_REQ}ST\r" | nc -w1 "$IP" "$PORT" \
                 | grep -o '\*D[0-9].*' | grep -v '\*IFSEION')
      if [[ -n "$resposta" ]]; then
        echo "[STATUS] Módulo $MOD_REQ => $resposta"
        ha entity update "input_text.ifsei_mod${MOD_REQ}_feedback" --value "$resposta" || true
      fi
      sleep 0.1
    done
  fi
  sleep 0.2
done
