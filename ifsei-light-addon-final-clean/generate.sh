#!/usr/bin/env bash

CONFIG="/data/options.json"
BASE="/config/.storage/Drivers/Scenario"
OUTPUT="$BASE/ifsei_lights.yaml"

mkdir -p "$BASE"

IP=$(jq -r .ip "$CONFIG")
PORT=$(jq -r .port "$CONFIG")

readarray -t MOD_DIMMER < <(jq -r '.["module-dimmer"][]?' "$CONFIG")
readarray -t MOD_ONOFF  < <(jq -r '.["module-onoff"][]?' "$CONFIG")
MODULES=("${MOD_DIMMER[@]}" "${MOD_ONOFF[@]}")

# Início do YAML unificado
cat > "$OUTPUT" <<EOF
shell_command:
  #ifsei_set: >-
    #/bin/bash -c echo -ne '\$D{{ mod }}Z{{ zone }}{{ ("%02d") % ((brightness | int * 63 // 255)) }}T0\r' | nc -w1 $IP $PORT"
  
  ifsei_stop_nc: "bash -c '/stop_nc.sh'"

  ifsei_set: >-
    bash -c "pkill -9 nc 2>/dev/null || true;
    sleep 0.01;
    pkill -9 nc 2>/dev/null || true;
    sleep 0.01;
    echo -ne '\$D{{ mod }}Z{{ zone }}{{ ("%02d") % ((brightness | int * 63 // 255)) }}T0\r' | nc -w1 $IP $PORT;
    sleep 0.01;
    echo -ne '\$D{{ mod }}Z{{ zone }}{{ ("%02d") % ((brightness | int * 63 // 255)) }}T0\r' | nc -w1 $IP $PORT;

  
input_text:
EOF

# Entidades de feedback
for MOD in "${MODULES[@]}"; do
  echo "  ifsei_mod${MOD}_feedback:" >> "$OUTPUT"
  echo "    name: Feedback módulo ${MOD}" >> "$OUTPUT"
  #echo "    initial: """ >> "$OUTPUT"
  echo "    max: 255" >> "$OUTPUT"
  echo "    mode: text" >> "$OUTPUT"
  echo "" >> "$OUTPUT"
done

# Cabeçalho da seção de luzes
cat >> "$OUTPUT" <<EOF
light:
  - platform: template
    lights:
EOF

# Módulos DIMMER
for MOD in "${MOD_DIMMER[@]}"; do
  for ZONE in $(seq 1 8); do
    ENTITY="luz_mod${MOD}_z${ZONE}"
    cat >> "$OUTPUT" <<EOF
      $ENTITY:
        friendly_name: "Scenario Classic [DIMMER] Mód $MOD Canal $ZONE"
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
  done
done

# Módulos ON/OFF
for MOD in "${MOD_ONOFF[@]}"; do
  for ZONE in $(seq 1 8); do
    ENTITY="luz_mod${MOD}_z${ZONE}"
    cat >> "$OUTPUT" <<EOF
      $ENTITY:
        friendly_name: "Scenario Classic [ON/OFF] Mód $MOD Canal $ZONE"
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
  done
done
