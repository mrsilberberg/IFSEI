#!/usr/bin/env bash
# Envia comando IFSEI via TCP e CR (0x0D no final)

IP=$(jq -r .ip /data/options.json)
PORT=$(jq -r .port /data/options.json)
CMD="$1"

if [ -z "$CMD" ]; then
  echo "Uso: $0 <comando>"
  exit 1
fi

# Adiciona <CR> no final do comando
printf '%s\r' "$CMD" | nc "$IP" "$PORT"
