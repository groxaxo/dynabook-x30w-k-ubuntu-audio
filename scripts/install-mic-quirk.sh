#!/usr/bin/env bash
set -euo pipefail

CONF=/etc/modprobe.d/99-sof-dmic-quirk.conf
BACKUP="${CONF}.bak.$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

if [[ -f "$CONF" ]]; then
  cp "$CONF" "$BACKUP"
  echo "Backed up existing config to $BACKUP"
fi

cat > "$CONF" <<'EOF'
options snd_sof_intel_hda_generic hda_model=laptop-dmic dmic_num=2
EOF

echo "Installed $CONF"
echo "Reboot required: sudo reboot"

