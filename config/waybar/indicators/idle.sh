#!/bin/bash

if pgrep -x hypridle >/dev/null; then
  echo '{"text": ""}'
else
  echo '{"text": "󱫖", "tooltip": "Bloqueio por inatividade desligado", "class": "active"}'
fi
