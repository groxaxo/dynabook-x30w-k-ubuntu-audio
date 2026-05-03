#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != "--i-understand" ]]; then
  cat >&2 <<'EOF'
This applies live Realtek HDA codec verbs used during debugging.

It did NOT fix speakers on the tested Dynabook X30W-K. It is only useful for
advanced testing and kernel bug reports. It is not persistent; reboot resets it.

Run only if you understand this:
  sudo ./experimental/apply-realtek-amp-verbs.sh --i-understand
EOF
  exit 2
fi

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo." >&2
  exit 1
fi

if ! command -v hda-verb >/dev/null 2>&1; then
  echo "hda-verb missing. Install with: sudo apt install alsa-tools" >&2
  exit 1
fi

dev=/dev/snd/hwC0D0

# Generic Realtek GPIO high test.
hda-verb "$dev" 0x01 SET_GPIO_MASK 0x7
hda-verb "$dev" 0x01 SET_GPIO_DIRECTION 0x7
hda-verb "$dev" 0x01 SET_GPIO_DATA 0x7
hda-verb "$dev" 0x14 SET_EAPD_BTLENABLE 0x2

# ALC287 Yoga-style speaker enable sequence from Linux realtek/alc269.c.
for seq in \
  "0x20 SET_COEF_INDEX 0x24" "0x20 SET_PROC_COEF 0x41" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0xc" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x1a" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0xf" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x42" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0x10" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x40" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0x2" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x24" "0x20 SET_PROC_COEF 0x46" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0xc" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x2a" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0xf" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x46" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0x10" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x44" "0x20 SET_PROC_COEF 0xb020" \
  "0x20 SET_COEF_INDEX 0x26" "0x20 SET_PROC_COEF 0x2" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0x0" "0x20 SET_PROC_COEF 0xb020"; do
  set -- $seq
  hda-verb "$dev" "$1" "$2" "$3"
done

echo "Applied experimental verbs. Run: speaker-test -D default -c 2 -t wav -l 2"

