# Working DMIC Fix Backup - 2026-05-25

This folder preserves the known-good Linux digital microphone configuration from
the Dynabook X30W-K after the spike-then-flatline problem was fixed.

## Hardware and OS

- Machine: Dynabook Portege X30W-K / `PDA31A`
- Codec: Realtek ALC257, subsystem `3100:011f`
- Audio stack: SOF + PipeWire + WirePlumber
- Kernel at backup time: Ubuntu OEM `6.17.0-1023-oem`

## Files Backed Up

- `99-sof-pdm1-topology.conf`
  - Installed at `/etc/modprobe.d/99-sof-pdm1-topology.conf`
  - Forces SOF to load `sof-hda-generic-2ch-pdm1.tplg`.
- `52-force-builtin-mic.lua`
  - Installed at `~/.config/wireplumber/main.lua.d/52-force-builtin-mic.lua`
  - Keeps the DMIC source preferred and stable.
- `51-disable-broken-dmic.lua.disabled`
  - Previous failed workaround, intentionally left disabled as a record.
- `audio-state.txt`
  - Captured PipeWire, ALSA, and mixer state when the microphone was working.

## Current Working Behavior

The default source is:

```text
alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source
```

Direct DMIC captures from `plughw:CARD=sofhdadsp,DEV=6` are stable over time and
do not show the previous startup-spike followed by silence.

## Restore Notes

To restore this backed-up state manually:

```bash
sudo install -m 0644 99-sof-pdm1-topology.conf /etc/modprobe.d/99-sof-pdm1-topology.conf
install -D -m 0644 52-force-builtin-mic.lua ~/.config/wireplumber/main.lua.d/52-force-builtin-mic.lua
install -D -m 0644 51-disable-broken-dmic.lua.disabled ~/.config/wireplumber/main.lua.d/51-disable-broken-dmic.lua.disabled
sudo reboot
```

Do not re-enable `51-disable-broken-dmic.lua.disabled`; it hides the DMIC source
and was superseded by the PDM1 topology fix.
