-- Keep the internal microphone routes stable on the Dynabook X30W-K.
alsa_monitor.rules = alsa_monitor.rules or {}

table.insert(alsa_monitor.rules, {
  matches = {
    { { "device.name", "matches", "alsa_card.pci-0000_00_1f.3" } },
  },
  apply_properties = {
    ["api.acp.auto-port"] = false,
    ["api.acp.auto-profile"] = false,
  },
})

-- Prefer the DMIC path. It needs the pdm1 SOF topology configured in modprobe.
table.insert(alsa_monitor.rules, {
  matches = {
    {
      { "node.name", "matches", "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp_6__source" },
    },
  },
  apply_properties = {
    ["priority.driver"] = 2300,
    ["priority.session"] = 2300,
    ["node.pause-on-idle"] = false,
  },
})

-- Keep the noisy HDA analog mic as a fallback, but do not let apps pick it first.
table.insert(alsa_monitor.rules, {
  matches = {
    {
      { "node.name", "matches", "alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__hw_sofhdadsp__source" },
    },
    {
      { "node.name", "matches", "alsa_input.pci-0000_00_1f.3.analog-stereo" },
    },
  },
  apply_properties = {
    ["priority.driver"] = 1200,
    ["priority.session"] = 1200,
    ["node.pause-on-idle"] = false,
  },
})
