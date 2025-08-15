#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"

IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
MQTT_HOST=$(jq -r .mqtt_host "$CONFIG")
MQTT_PORT=$(jq -r .mqtt_port "$CONFIG")
MQTT_USER=$(jq -r .mqtt_username "$CONFIG")
MQTT_PASS=$(jq -r .mqtt_password "$CONFIG")
TOPIC_PREFIX=$(jq -r .mqtt_topic_prefix "$CONFIG")
LAST_LINE=""
LOG_FILE="/config/ifsei_feedback.log"

# Tempo mínimo entre requisições por módulo (segundos)
MIN_INTERVAL=2

# Carrega lista de módulos do options.json
readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

# Armazena último envio para cada módulo
declare -A LAST_REQ_TIME

echo "=============================="
echo "  IFSEI Add-on - Feedback em tempo real com reconexão"
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Módulos: ${MODULES[*]}"
echo "Log: $LOG_FILE"
echo "=============================="

echo "🔎 Testando conexão MQTT..."
if ! mosquitto_pub -h "$MQTT_HOST" -p "$MQTT_PORT" -u "$MQTT_USER" -P "$MQTT_PASS" \
  -t "$TOPIC_PREFIX/test" -m "IFSEI MQTT connected at $(date)"; then
  echo "❌ Erro: Falha ao conectar ao broker MQTT!"
  exit 1
fi
echo "✅ Conexão MQTT bem-sucedida!"

# Ativa MON6
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.5

# Loop de reconexão
while true; do
  echo "[INFO] Conectando ao IFSEI..."
  
  nc -w1 "$IP" "$PORT" | tee -a "$LOG_FILE" | while read -r line; do
    echo "[RECEBIDO] $line"

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
            echo "$resposta" >> "$LOG_FILE"
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

  echo "[WARN] Conexão perdida. Tentando reconectar em 1s..."
  sleep 1
done
