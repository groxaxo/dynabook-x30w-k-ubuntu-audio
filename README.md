# Dynabook X30W-K Ubuntu Audio Notes

Workarounds and diagnostics for Ubuntu audio on the Dynabook / Toshiba Portege X30W-K.

This repo was created from live debugging on:

- Model: Dynabook Portege X30W-K / `PDA31A`
- Audio controller: Intel Alder Lake PCH-P HDA, PCI ID `8086:51c8`
- Codec: Realtek ALC257, subsystem `3100:011f`
- Kernel tested: Ubuntu OEM `6.17.0-1017-oem`

## Current Status

Confirmed:

- Internal microphone can be exposed again by forcing the Realtek `laptop-dmic` HDA model.
- PipeWire can record from the internal mic after the quirk is loaded.
- Speaker/Headphones sink can be selected and unmuted from software.

Not confirmed:

- Internal speakers are not fixed yet on the tested machine.
- The likely missing piece is a Dynabook/Realtek smart-amplifier initialization quirk in the Linux HDA driver.
- Windows driver files reference Realtek external amp handling (`ExtAmp1308` / `ExtAmp1318`), but the Linux kernel does not currently appear to have an exact Dynabook quirk for this subsystem.

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
Alder Lake PCH-P High Definition Audio Controller Internal Stereo Microphone
```

Do not choose a `monitor` source unless you intentionally want to record system playback.

## Debug Bundle

Collect useful hardware and PipeWire diagnostics:

```bash
./scripts/collect-debug-info.sh
```

This writes a timestamped `dynabook-audio-debug-*.tar.gz` file in the current directory.

## Speaker Smart-Amp Notes

See [docs/speaker-smart-amp-status.md](docs/speaker-smart-amp-status.md).

The speaker path may show as selected, unmuted, and active while no sound comes out. That usually means the Realtek codec pin is routed but the external speaker amp is still off.

## Windows Driver Backup

If you still have the original Windows partition, see [docs/windows-driver-backup-from-ubuntu.md](docs/windows-driver-backup-from-ubuntu.md). It explains how to copy the Windows Driver Store from Ubuntu for later restoration on Windows.

## Safety

The normal scripts only set ALSA/PipeWire defaults and one persistent module option.

The `experimental/` script applies live Realtek codec verbs. It is intentionally not part of quick start because it did not fix the tested machine's speakers and should only be used by people collecting data for kernel debugging.

