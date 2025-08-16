#!/usr/bin/env bash
# Mata todas as conexões netcat no container
pkill -9 nc 2>/dev/null || true
killall nc
killall -q nc

