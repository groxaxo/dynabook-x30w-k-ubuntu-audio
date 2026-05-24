# SoundWire SDCA Audio Stack — Definitive Diagnosis (2026-05-25)

> Supersedes the speaker-amp section of `speaker-smart-amp-status.md`.
> The HDA-codec smart-amp theory was wrong. The actual hardware uses
> SoundWire SDCA, not an HDA-attached external amplifier.

## TL;DR

The Dynabook Portege X30W-K speakers and headset are **not** wired through
the Realtek ALC257 HDA codec. They are SoundWire SDCA devices on the Intel
Alder Lake PCH SoundWire host controller. The HDA codec's `Speaker` and
`Headphone` pins that PipeWire exposes are essentially unconnected — toggling
EAPD, GPIO, or codec coefficients on them can never produce sound.

Linux does not yet have a machine-driver entry for this exact SoundWire
endpoint layout, so the SoundWire bus is not enumerated and no `RT1316`
amplifier driver is bound. Speakers are silent as a result.

## Hardware (decoded from DSDT `_ADR` values)

| ACPI dev | SDW link | Codec | Role |
|----------|----------|-------|------|
| SWD0 | 0 | RT711 (SDCA) | Headset codec (jack + analog mic) |
| SWD3 | 1 | RT714 (SDCA) | Digital array microphone |
| SWD2 | 2 | RT1316 (SDCA) | Speaker amplifier — left |
| SWD1 | 3 | RT1316 (SDCA) | Speaker amplifier — right |

`SWD4` and `SWD5` carry `sdw_version=0` and are stale stubs (ignored by Linux).

DSDT marker confirming Realtek SoundWire smart-amp parts:

```
"mipi-rtk-part-smartamp-private-prop"
```

Decoder script and raw DSDT are in `diagnostics/`.

## Why current SOF stack does not see the speakers

`/etc/modprobe.d/99-sof-pdm1-topology.conf` forces SOF to load:

```
intel/sof-tplg/sof-hda-generic-2ch-pdm1.tplg
```

That is an **HDA-only** topology. It tells SOF firmware to bring up
the HDA link and the digital-mic NHLT pipeline only; SoundWire links are
never initialised. Sysfs confirms it:

```
$ ls /sys/bus/soundwire/devices/
(empty)
```

Even without that forced topology, mainline Linux 6.17 has no
`snd_soc_acpi_mach` entry matching our SDW link assignment
(RT711@l0, RT714@l1, RT1316@l2+l3, link_mask 0xF). The closest stock
entries in `sound/soc/intel/common/soc-acpi-intel-adl-match.c`:

| Topology | RT711 | RT714 | RT1316 |
|----------|-------|-------|--------|
| `sof-adl-rt711-l0-rt1316-l12-rt714-l3` | l0 | l3 | l1+l2 |
| `sof-adl-rt711-l0-rt1316-l13-rt714-l2` | l0 | l2 | l1+l3 |
| `sof-adl-rt711-l2-rt1316-l01-rt714-l3` | l2 | l3 | l0+l1 |
| **Ours**                                | **l0** | **l1** | **l2+l3** |

None match. There is also no corresponding pre-compiled topology
`sof-adl-rt711-l0-rt1316-l23-rt714-l1.tplg` in `linux-firmware` /
`firmware-sof-signed`.

## What it takes to fix it properly

This is upstream-kernel + SOF-firmware work, not a runtime workaround:

1. **Add a machine match** in `sound/soc/intel/common/soc-acpi-intel-adl-match.c`:

   ```c
   static const struct snd_soc_acpi_endpoint single_endpoint = { ... };

   static const struct snd_soc_acpi_adr_device rt711_0_adr[] = {
       { .adr = 0x000030025D071100ull, .num_endpoints = 1,
         .endpoints = &single_endpoint, .name_prefix = "rt711" }
   };
   static const struct snd_soc_acpi_adr_device rt714_1_adr[] = {
       { .adr = 0x000130025D071400ull, .num_endpoints = 1,
         .endpoints = &single_endpoint, .name_prefix = "rt714" }
   };
   static const struct snd_soc_acpi_adr_device rt1316_2_group2_adr[] = {
       { .adr = 0x000230025D131600ull, .num_endpoints = 1,
         .endpoints = &spk_l_endpoint, .name_prefix = "rt1316-1" }
   };
   static const struct snd_soc_acpi_adr_device rt1316_3_group2_adr[] = {
       { .adr = 0x000330025D131600ull, .num_endpoints = 1,
         .endpoints = &spk_r_endpoint, .name_prefix = "rt1316-2" }
   };

   static const struct snd_soc_acpi_link_adr adl_sdw_rt711_l0_rt1316_l23_rt714_l1[] = {
       { .mask = BIT(0), .num_adr = 1, .adr_d = rt711_0_adr },
       { .mask = BIT(1), .num_adr = 1, .adr_d = rt714_1_adr },
       { .mask = BIT(2), .num_adr = 1, .adr_d = rt1316_2_group2_adr },
       { .mask = BIT(3), .num_adr = 1, .adr_d = rt1316_3_group2_adr },
       {}
   };

   /* … and add to snd_soc_acpi_intel_adl_sdw_machines[]:
      { .link_mask = 0xF, .links = adl_sdw_rt711_l0_rt1316_l23_rt714_l1,
        .drv_name = "sof_sdw",
        .sof_tplg_filename = "sof-adl-rt711-l0-rt1316-l23-rt714-l1.tplg" } */
   ```

2. **Generate the SOF topology**: build `alsatplg` topology2 from
   <https://github.com/thesofproject/sof> with the matching pipeline graph.
   The closest reference is the existing `sof-adl-rt711-l0-rt1316-l12-rt714-l3.tplg`
   source; clone its link assignment to l2/l3 (spk) and l1 (rt714 mic).

3. **Optionally** rebuild only the `snd-soc-acpi-intel-match` module
   out-of-tree against `/lib/modules/$(uname -r)/build` to test (1) without
   a full kernel rebuild. The `sof_sdw` machine driver itself does not
   need changes — it consumes whatever `snd_soc_acpi_mach` produces.

4. Submit the patch + topology upstream
   (`alsa-devel@alsa-project.org`, `sound-open-firmware/sof`).

## Why we have not done (1)–(3) yet

- Without (2), step (1) only causes SOF to fail topology load and leave
  the speakers silent and the mic broken. The topology file must exist on
  disk before the machine entry will produce sound.
- Building (2) requires the SOF dev toolchain and is a multi-hour task with
  a non-trivial risk of leaving the user with no audio at all and
  needing recovery-mode steps.
- This needs to be done with care on a system the user actually depends
  on; it belongs in a separate, dedicated maintenance window with a
  bootable USB rescue stick handy.

## What works in the meantime

- **Microphone**: forced SOF + `sof-hda-generic-2ch-pdm1.tplg`
  (the existing fix; see `docs/working-dmic-fix-2026-05-25.md`).
- **Speakers**: external USB or Bluetooth audio device.
- **No-software-only path** exists today for the internal speakers on
  this exact model with current Linux/SOF.

## Upstream bug report template

When filing the bug, include:

- `diagnostics/dsdt.dsl.gz` (full DSDT)
- `diagnostics/soundwire-topology.txt` (decoded SDW endpoint table)
- The link/codec table above
- Kernel: 6.17.0-1023-oem (Ubuntu 24.04)
- PCI HDA: `8086:51c8` (Intel Alder Lake PCH-P HDA / SoundWire host)
- HDA codec subsystem: `3100:011f` (Dynabook)
- Mention that DSDT contains
  `"mipi-rtk-part-smartamp-private-prop"` and that all 4 SoundWire links
  are populated.

Suggested upstream destinations:

- `alsa-devel@alsa-project.org` (mailing list)
- <https://bugzilla.kernel.org/> under `ALSA: HDA / SoundWire`
- <https://github.com/thesofproject/linux/issues>
