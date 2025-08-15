#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LAST_LINE=""
LOG_FILE="/config/ifsei_feedback.log"

# Tempo mínimo entre requisições por módulo (segundos)
MIN_INTERVAL=2

# Carrega lista de módulos
readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

declare -A LAST_REQ_TIME

echo "=============================="
echo "  IFSEI Parser - Processa LOG_FILE"
echo "=============================="
echo "Módulos: ${MODULES[*]}"
echo "Log: $LOG_FILE"
echo "=============================="

tail -n0 -f "$LOG_FILE" | while read -r line; do
  # Filtra apenas feedbacks *Dxx e ignora *IFSEION
  if [[ "$line" =~ ^\*D[0-9]{2} ]] && [[ "$line" != *IFSEION* ]]; then
    if [[ "$line" != "$LAST_LINE" ]]; then
      LAST_LINE="$line"
      echo "[EVENTO NOVO DETECTADO] $line"

      now=$(date +%s)
      for MOD_REQ in "${MODULES[@]}"; do
        last_time=${LAST_REQ_TIME[$MOD_REQ]:-0}
        if (( now - last_time < MIN_INTERVAL )); then
          echo "[INFO] Ignorando módulo $MOD_REQ (intervalo mínimo não atingido)"
          continue
        fi

        echo "📡 Solicitando status do módulo $MOD_REQ"
        resposta=$(echo -ne "\$D${MOD_REQ}ST\r" | nc -w1 "$IP" "$PORT" \
                   | grep -o '\*D[0-9].*' | grep -v '\*IFSEION')

        if [[ -n "$resposta" ]]; then
          echo "[STATUS M${MOD_REQ}] $resposta"
          ha entity update "input_text.ifsei_mod${MOD_REQ}_feedback" --value "$resposta" || true
          LAST_REQ_TIME[$MOD_REQ]=$now
        else
          echo "[AVISO] Nenhum retorno para módulo $MOD_REQ"
        fi

        sleep 0.05
      done
    fi
  fi
done
