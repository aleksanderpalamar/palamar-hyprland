#!/bin/bash

if makoctl mode | grep -qx do-not-disturb; then
  echo '{"text": "󰂛", "tooltip": "Notificações silenciadas", "class": "active"}'
else
  echo '{"text": ""}'
fi
