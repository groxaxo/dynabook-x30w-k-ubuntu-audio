# Working Digital Microphone Fix - 2026-05-25

This documents the current working microphone fix before further speaker
experiments.

## Symptom

The built-in digital microphone originally recorded a loud startup spike and then
collapsed to near-silence on Linux. Windows did not show the same failure.

## Root Cause Found

The standard SOF HDA generic topology did not match this Dynabook's digital mic
wiring. Loading the PDM controller 1 topology makes the DMIC PCM stable.

Kernel messages confirmed the active topology changed from:

```text
intel/sof-tplg/sof-hda-generic-2ch.tplg
```

to:

```text
intel/sof-tplg/sof-hda-generic-2ch-pdm1.tplg
```

## Persistent Fix

Install this module option:

```text
options snd_sof tplg_filename=sof-hda-generic-2ch-pdm1.tplg
```

The live machine stores it at:

```text
/etc/modprobe.d/99-sof-pdm1-topology.conf
```

The live machine also still has the earlier model-selection file:

```text
/etc/modprobe.d/99-sof-dmic-quirk.conf
```

with:

```text
options snd_sof_intel_hda_generic hda_model=laptop-dmic
```

That file is backed up for reproducibility. The PDM1 topology is the part that
fixed the spike-then-flatline DMIC behavior.

WirePlumber then keeps the DMIC source preferred with:

```text
~/.config/wireplumber/main.lua.d/52-force-builtin-mic.lua
```

The default source should be:

```text
alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source
```

## Validation

Use this direct ALSA capture test:

```bash
arecord -D plughw:CARD=sofhdadsp,DEV=6 -f S32_LE -r 48000 -c 2 -d 5 /tmp/dmic-test.wav
```

A healthy capture remains active for the full duration and has sustained signal
instead of only an initial spike.

## Speaker Test Caveat

The internal speakers are still a separate problem. A speaker-to-microphone
loopback test can fail even when the microphone is fixed, because Linux currently
does not initialize the laptop speaker smart amplifier correctly.
