#!/bin/bash
# Zorza OS – inicjalizacja sesji użytkownika (autostart).
STATE="$HOME/.config/zorza"
mkdir -p "$STATE"
sleep 4
if [ ! -e "$STATE/initialized" ]; then
  # Efekty tylko gdy jest akceleracja 3D (VirtualBox bez 3D → wyłączone)
  /usr/bin/zorza-appearance effects auto
  /usr/bin/zorza-appearance accent "$(kreadconfig6 --file zorzarc --group General --key Accent --default violet)"
  touch "$STATE/initialized"
fi
if [ ! -e "$STATE/welcome-done" ]; then
  exec /usr/bin/zorza-welcome
fi
