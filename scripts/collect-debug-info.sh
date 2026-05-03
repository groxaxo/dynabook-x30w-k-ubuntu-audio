#!/usr/bin/env bash
set -euo pipefail

stamp=$(date +%Y%m%d-%H%M%S)
dir="dynabook-audio-debug-$stamp"
archive="$dir.tar.gz"

mkdir -p "$dir"

run() {
  local name=$1
  shift
  {
    echo "\$ $*"
    "$@"
  } > "$dir/$name.txt" 2>&1 || true
}

run uname uname -a
run lspci-audio lspci -nnk -s 00:1f.3
run lsmod-audio bash -lc "lsmod | grep -E 'snd|sof|hda|soundwire|codec' | sort"
run asound-cards cat /proc/asound/cards
run aplay aplay -l
run arecord arecord -l
run wpctl wpctl status
run pactl-info pactl info
run pactl-sinks pactl list sinks
run pactl-sources pactl list sources
run amixer amixer -c 0
run modprobe-quirk bash -lc "cat /etc/modprobe.d/99-sof-dmic-quirk.conf 2>/dev/null || true"
run sof-params bash -lc "for p in /sys/module/snd_sof_intel_hda_generic/parameters/*; do echo \"== $p ==\"; cat \"$p\"; done"
run codec0 cat /proc/asound/card0/codec#0
run dmesg-audio sudo dmesg

tar -czf "$archive" "$dir"
echo "Wrote $archive"

