#!/usr/bin/env bash
set -euo pipefail

SINK='alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__sink'

if command -v wpctl >/dev/null 2>&1; then
  id=$(wpctl status | awk '/Speaker \+ Headphones/ {gsub("\\.","",$1); print $1; exit}')
  if [[ -n "${id:-}" ]]; then
    wpctl set-default "$id"
    wpctl set-mute "$id" 0
    wpctl set-volume "$id" 0.80
  fi
fi

if command -v pactl >/dev/null 2>&1 && pactl list short sinks | grep -q "$SINK"; then
  pactl set-default-sink "$SINK"
  pactl set-sink-mute "$SINK" 0
  pactl set-sink-volume "$SINK" 80%
fi

if command -v amixer >/dev/null 2>&1; then
  amixer -c 0 set Master unmute 80% >/dev/null || true
  amixer -c 0 set Speaker unmute 80% >/dev/null || true
  amixer -c 0 set 'Auto-Mute Mode' Disabled >/dev/null 2>&1 || true
fi

echo "Selected and unmuted the onboard Speaker + Headphones sink where available."
echo "Run: speaker-test -D default -c 2 -t wav -l 2"

