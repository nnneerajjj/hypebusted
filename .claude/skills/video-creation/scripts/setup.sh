#!/usr/bin/env bash
# Build (or repair) the local video workspace. Safe to re-run; it only fetches what is missing.
#
#   setup.sh [WORKDIR]            default WORKDIR: ~/hypebusted-video
#
# Optional environment:
#   KOKORO_SRC=/dir/with/kokoro-files   copy the Kokoro model from here instead of downloading it (about 350 MB)
#
# Result: WORKDIR/{venv,fonts,kokoro,audio,out} plus the scripts copied from this skill's scripts/ folder.
# Everything runs on the CPU. No GPU, no paid services, no API keys.
set -euo pipefail

WORK="${1:-$HOME/hypebusted-video}"
SKILL_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(cd "$SKILL_SCRIPTS/../../../.." && pwd)"   # repo root: .claude/skills/video-creation/scripts -> 4 levels up
KOKORO_URL="https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0"

mkdir -p "$WORK"/{fonts,kokoro,audio,out}

echo "== Python environment"
if [ ! -x "$WORK/venv/bin/python" ]; then
  # --system-site-packages reuses the system Pillow and numpy when present
  python3 -m venv --system-site-packages "$WORK/venv"
fi
"$WORK/venv/bin/pip" install -q --upgrade pip
# imageio-ffmpeg ships an ffmpeg binary (this machine has no system ffmpeg). kokoro-onnx = the narration voice.
# fonttools+brotli convert the site's woff2 fonts to ttf for Pillow. rembg cuts people out for thumbnails.
"$WORK/venv/bin/pip" install -q pillow numpy imageio-ffmpeg fonttools brotli kokoro-onnx soundfile "rembg[cpu]"

echo "== Fonts (from the site, so videos match hypebusted.com)"
"$WORK/venv/bin/python" - "$PROJECT/app/assets/fonts" "$WORK/fonts" <<'PY'
import os, sys
from fontTools.ttLib import TTFont
src, dst = sys.argv[1], sys.argv[2]
for n in sorted(os.listdir(src)):
    if not n.endswith(".woff2"):
        continue
    out = os.path.join(dst, n.replace(".woff2", ".ttf"))
    if not os.path.exists(out):
        f = TTFont(os.path.join(src, n)); f.flavor = None; f.save(out)
    print("  ", os.path.basename(out))
PY

echo "== Kokoro voice model"
for f in kokoro-v1.0.onnx voices-v1.0.bin; do
  if [ ! -s "$WORK/kokoro/$f" ]; then
    if [ -n "${KOKORO_SRC:-}" ] && [ -s "$KOKORO_SRC/$f" ]; then
      cp "$KOKORO_SRC/$f" "$WORK/kokoro/$f"
    else
      curl -L --fail -C - -o "$WORK/kokoro/$f" "$KOKORO_URL/$f"
    fi
  fi
  echo "   $f $(du -h "$WORK/kokoro/$f" | cut -f1)"
done

echo "== Scripts"
cp "$SKILL_SCRIPTS"/*.py "$WORK/"
ls "$WORK"/*.py | sed 's|^|   |'

echo
echo "Ready: $WORK"
echo "  cd $WORK && ./venv/bin/python narration.py && ./venv/bin/python make_video.py preview"
