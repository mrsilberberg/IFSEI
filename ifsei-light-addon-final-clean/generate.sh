#!/usr/bin/env bash

CONFIG="/data/options.json"
BASE="/config/.storage/Drivers/Scenario"
LIGHTS="$BASE/ifsei_lights.yaml"
COMMANDS="$BASE/ifsei_commands.sh"

mkdir -p "$BASE"

IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")

# Arrays (podem estar vazios)
readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")

# Junta todos os módulos em uma variável única
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

# Cabeçalho do YAML
cat > "$LIGHTS" <<EOF
# ===========================
# Arquivo gerado pelo Add-on IFSEI
# Contém entidades light.template e shell_command para módulos Scenario
# ===========================

shell_command:
  ifsei_set: >-
    /bin/bash -c "echo -ne '\$D{{ mod }}Z{{ zone }}{{ ("%02d") % ((brightness | int * 63 // 255)) }}T0\r' | nc -w1 $IP $PORT"

light:
  - platform: template
    lights:
EOF

# Cabeçalho dos comandos diretos
echo "# Comandos para IFSEI no IP $IP porta $PORT" > "$COMMANDS"

# Loop para módulos DIMMER
for MOD in "${MOD_DIMMER[@]}"; do
  for ZONE in $(seq 1 8); do
    ENTITY="luz_mod${MOD}_z${ZONE}"

    cat >> "$LIGHTS" <<EOF
      # ------------------------
      # Módulo: $MOD | Zona: $ZONE
      $ENTITY:
        friendly_name: "Scenario Classic Mód $MOD Canal $ZONE"
        turn_on:
          service: shell_command.ifsei_set
          data:
            mod: "$MOD"
            zone: "$ZONE"
            brightness: 255
        turn_off:
          service: shell_command.ifsei_set
          data:
            mod: "$MOD"
            zone: "$ZONE"
            brightness: 0
        set_level:
          service: shell_command.ifsei_set
          data_template:
            mod: "$MOD"
            zone: "$ZONE"
            brightness: "{{ brightness }}"

EOF

    # Comandos de exemplo para dimmer
    echo "echo -ne \"\$D${MOD}Z${ZONE}63T0\r\" | nc -w1 $IP $PORT   # Máximo" >> "$COMMANDS"
    echo "echo -ne \"\$D${MOD}Z${ZONE}30T0\r\" | nc -w1 $IP $PORT   # Meio" >> "$COMMANDS"
    echo "echo -ne \"\$D${MOD}Z${ZONE}00T0\r\" | nc -w1 $IP $PORT   # Desligado" >> "$COMMANDS"
  done
done

# Loop para módulos ON/OFF
for MOD in "${MOD_ONOFF[@]}"; do
  for ZONE in $(seq 1 8); do
    ENTITY="luz_mod${MOD}_z${ZONE}"

    cat >> "$LIGHTS" <<EOF
      # ------------------------
      # Módulo: $MOD | Zona: $ZONE
      $ENTITY:
        friendly_name: "Scenario Classic Mód $MOD Canal $ZONE"
        turn_on:
          service: shell_command.ifsei_set
          data:
            mod: "$MOD"
            zone: "$ZONE"
            brightness: 255
        turn_off:
          service: shell_command.ifsei_set
          data:
            mod: "$MOD"
            zone: "$ZONE"
            brightness: 0

EOF

    # Comandos de exemplo para on/off
    echo "echo -ne \"\$D${MOD}Z${ZONE}63T0\r\" | nc -w1 $IP $PORT   # Ligar" >> "$COMMANDS"
    echo "echo -ne \"\$D${MOD}Z${ZONE}00T0\r\" | nc -w1 $IP $PORT   # Desligar" >> "$COMMANDS"
  done
done
