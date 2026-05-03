#!/usr/bin/env bash
set -euo pipefail

echo "== Audio devices =="
wpctl status | sed -n '/Audio/,/Video/p' || true

echo
echo "== ALSA playback =="
aplay -l || true

echo
echo "== ALSA capture =="
arecord -l || true

echo
echo "== Defaults =="
pactl get-default-sink 2>/dev/null || true
pactl get-default-source 2>/dev/null || true

echo
echo "== Five-second mic test =="
out="/tmp/dynabook-mic-test.wav"
rm -f "$out"
arecord -q -D default -f S16_LE -r 48000 -c 2 -d 5 "$out"
python3 - "$out" <<'PY'
import math
import struct
import sys
import wave

path = sys.argv[1]
with wave.open(path, "rb") as w:
    data = w.readframes(w.getnframes())
vals = struct.unpack("<%dh" % (len(data) // 2), data) if data else []
rms = math.sqrt(sum(v * v for v in vals) / len(vals)) if vals else 0
peak = max(map(abs, vals)) if vals else 0
print(f"{path}: rms_pct={rms / 32768 * 100:.3f} peak_pct={peak / 32768 * 100:.3f}")
PY

echo
echo "== Speaker test =="
echo "Listen for left/right voice prompts."
speaker-test -D default -c 2 -t wav -l 2

