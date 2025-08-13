#!/usr/bin/env bash
set -euo pipefail

CONFIG="/data/options.json"
IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")
LOG_FILE="/config/ifsei_feedback.log"

echo "=============================="
echo "  IFSEI Add-on - Modo Feedback "
echo "=============================="
echo "IP: $IP"
echo "Porta: $PORT"
echo "Log: $LOG_FILE"
echo "=============================="

# 1️⃣ Ativa MON6 (uma vez)
echo "⚙️ Ativando MON6..."
echo -ne '$MON6\r' | nc -w1 "$IP" "$PORT" || true
sleep 0.2

# 2️⃣ Inicia listener passivo (apenas C00, sobrescrevendo)
echo "📡 Iniciando listener passivo (apenas C00, sobrescrevendo)..."

while true; do
    nc "$IP" "$PORT" \
    | tr -d '\r' \
    | while read -r linha; do
        echo "🔹 Recebido: $linha"  # log bruto

        # Remove > e * do início
        clean="${linha#>}"
        clean="${clean#\*}"
        echo "🔹 Limpo: $clean"  # log limpo

        # Filtra somente C00
        case "$clean" in
            D??C00Z*)
                echo "✅ Gravando no arquivo: $clean"
                echo "$clean" > "$LOG_FILE"
                ;;
            *)
                echo "⏭️ Ignorado (não é C00)"
                ;;
        esac
    done

    echo "⚠️ Conexão encerrada. Tentando reconectar em 2s..."
    sleep 2
done

