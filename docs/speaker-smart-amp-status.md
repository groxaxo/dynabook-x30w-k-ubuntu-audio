# Speaker Smart-Amp Status

On the tested Dynabook X30W-K, Linux reports the Realtek ALC257 speaker pin as present, powered, unmuted, and routed:

- Codec: `Realtek ALC257`
- Vendor ID: `0x10ec0257`
- Subsystem ID: `0x3100011f`
- Speaker pin: `0x14`
- Pin default: `0x90170110`, fixed internal speaker
- EAPD: enabled

Despite that, no sound was audible from the internal speakers during testing.

## Why This Looks Like a Smart-Amp Issue

The Windows Realtek package for this machine includes `RTKVHD64.sys` and references:

- `ExtAmp1308`
- `ExtAmp1318`
- `SmartAMPProcessThread`
- `IOCTL_AMP_SET_SPEAKER_MUTE`
- `AMP_GlobalINFO`

That strongly suggests the laptop speaker path requires an external Realtek amp initialization sequence beyond the normal HDA speaker pin setup.

## What Was Tried

The following were tested live:

- PipeWire default sink selection
- ALSA `Master` and `Speaker` unmute/volume
- EAPD enable on speaker pin `0x14`
- Realtek GPIO mask/direction/data high for GPIO bits `0x1`, `0x2`, `0x4`, and `0x7`
- Linux model override `hda_model=alc287-ideapad-bass-spk-amp`
- ALC287 Yoga speaker coefficient sequence from Linux `sound/hda/codecs/realtek/alc269.c`
- ALC1318-style coefficient sequence from Linux `alc287_fixup_lenovo_thinkpad_with_alc1318`

None produced confirmed speaker output on the tested machine.

## Recommended Next Step

Collect diagnostics:

```bash
./scripts/collect-debug-info.sh
```

Then file an upstream ALSA/kernel bug with:

- The debug bundle
- Laptop model and BIOS version
- The codec details above
- The Windows Realtek driver version if available
- Mention that the Windows package references `ExtAmp1308` / `ExtAmp1318`

Do not manually copy Windows `.sys` files into Ubuntu or Windows system directories.

