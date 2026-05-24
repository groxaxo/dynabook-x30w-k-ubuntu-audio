# Dynabook X30W-K Ubuntu Audio Notes

Workarounds and diagnostics for Ubuntu audio on the Dynabook / Toshiba Portege X30W-K.

This repo was created from live debugging on:

- Model: Dynabook Portege X30W-K / `PDA31A`
- Audio controller: Intel Alder Lake PCH-P HDA, PCI ID `8086:51c8`
- Codec: Realtek ALC257, subsystem `3100:011f`
- Kernel tested: Ubuntu OEM `6.17.0-1017-oem`

## Current Status

Confirmed:

- Digital microphone is stable when SOF loads `sof-hda-generic-2ch-pdm1.tplg`.
- PipeWire can record from the DMIC after the PDM1 topology and WirePlumber preference are loaded.
- Speaker/Headphones sink can be selected and unmuted from software.

Not confirmed:

- Internal speakers are not fixed yet on the tested machine.
- Root cause identified 2026-05-25: speakers are SoundWire SDCA RT1316
  amps on links 2 and 3, not HDA codec amps. Linux 6.17 has no machine
  match for this exact link layout (RT711@l0, RT714@l1, RT1316@l2+l3)
  and no pre-compiled SOF topology for it either. See
  [docs/soundwire-sdca-diagnosis-2026-05-25.md](docs/soundwire-sdca-diagnosis-2026-05-25.md).
- Fixing this requires an upstream kernel patch plus a new SOF topology
  file; it cannot be done as a runtime-only workaround.

## Quick Start

Install the microphone quirk:

```bash
sudo ./scripts/install-mic-quirk.sh
sudo reboot
```

After reboot, test audio:

```bash
./scripts/test-audio.sh
```

If speakers are muted or on the wrong default sink:

```bash
./scripts/unmute-speakers.sh
```

For Audacity, choose this recording device:

```text
Alder Lake PCH-P High Definition Audio Controller Digital Microphone
```

Do not choose a `monitor` source unless you intentionally want to record system playback.

## Debug Bundle

Collect useful hardware and PipeWire diagnostics:

```bash
./scripts/collect-debug-info.sh
```

This writes a timestamped `dynabook-audio-debug-*.tar.gz` file in the current directory.

## Speaker Status

**Updated 2026-05-25**: The speakers are **not** Realtek HDA smart-amps as
previously assumed. They are SoundWire SDCA RT1316 amplifiers on a stack
that Linux has no machine-driver entry for yet. See
[docs/soundwire-sdca-diagnosis-2026-05-25.md](docs/soundwire-sdca-diagnosis-2026-05-25.md)
for the full breakdown, decoded SoundWire topology, what an upstream patch
needs to contain, and why a runtime workaround is not possible on stock
Ubuntu 24.04 / kernel 6.17 today.

The older HDA-smart-amp investigation notes are kept for history in
[docs/speaker-smart-amp-status.md](docs/speaker-smart-amp-status.md);
they are superseded by the SoundWire diagnosis.

## Working Microphone Fix Backup

The known-good DMIC configuration from 2026-05-25 is backed up in
[`backups/2026-05-25-working-dmic-fix`](backups/2026-05-25-working-dmic-fix).
See [`docs/working-dmic-fix-2026-05-25.md`](docs/working-dmic-fix-2026-05-25.md)
for the implementation notes and validation command.

## Windows Driver Backup

If you still have the original Windows partition, see [docs/windows-driver-backup-from-ubuntu.md](docs/windows-driver-backup-from-ubuntu.md). It explains how to copy the Windows Driver Store from Ubuntu for later restoration on Windows.

## Safety

The normal scripts only set ALSA/PipeWire defaults and one persistent module option.

The `experimental/` script applies live Realtek codec verbs. It is intentionally not part of quick start because it did not fix the tested machine's speakers and should only be used by people collecting data for kernel debugging.
