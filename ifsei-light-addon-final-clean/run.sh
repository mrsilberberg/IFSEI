#!/usr/bin/env bash
echo "Gerando arquivos YAML e comandos..."
/generate.sh
echo "Finalizado."

echo "Iniciando monitoramento de feedback Deamon..."
/feedback_daemon.sh
