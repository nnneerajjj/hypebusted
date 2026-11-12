# Local toolchain: what is installed, where, and how to use it

Everything runs on this one machine (Linux, 12 CPU cores, 14 GB RAM, Intel Iris Xe graphics only, **no GPU compute**). No paid services, no API keys. Disk was about 87 GB free when this was written.

## Permanent workspace: `~/hypebusted-video/`

Built by `scripts/setup.sh` in this skill (about 30 seconds, idempotent). Re-run it after a reboot or on a new machine: `.claude/skills/video-creation/scripts/setup.sh`. To avoid re-downloading the voice model set `KOKORO_SRC=/dir/containing/kokoro-files`.

| Path | What it is |
|---|---|
| `venv/` | Python venv (inherits system Pillow and numpy). Installed: pillow, numpy, imageio-ffmpeg, fonttools, brotli, kokoro-onnx, soundfile, rembg[cpu] |
| `fonts/` | `space-grotesk.ttf` (headings), `dm-sans.ttf` (body), `dm-mono-400/500.ttf` (labels). Converted from the site's `app/assets/fonts/*.woff2` so videos match hypebusted.com. Variable fonts: set the weight with `set_variation_by_axes([weight])` |
| `kokoro/` | `kokoro-v1.0.onnx` (about 310 MB) and `voices-v1.0.bin` (about 27 MB). From https://github.com/thewh1teagle/kokoro-onnx/releases/tag/model-files-v1.0 |
| `audio/` | narration clips `00.wav...`, `durations.json` (clip lengths), `track.wav`, Short audio |
| `out/` | renders, thumbnails, subtitles |
| `*.py` | copies of this skill's `scripts/` (edit the workspace copies per video; keep improvements in the skill) |

ffmpeg: no system ffmpeg. Use the bundled binary: `./venv/bin/python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"`.

## Scripts (`scripts/`)

| Script | Does |
|---|---|
| `setup.sh` | builds the workspace above |
| `narration.py` | `LINES` (one per scene) to Kokoro clips, trimmed and normalized; writes `audio/durations.json`; `build_track()` lays clips into one timeline. `LEAD`/`TAIL` (0.2 s / 0.3 s) are the only pauses between lines |
| `make_video.py` | 1920x1080 explainer renderer. Scenes are Python functions drawing with Pillow at 2x supersampling; `DURS` is derived from narration; progress bar; `preview` and `render` |
| `make_short.py` | 1080x1920 Short, narration-first pacing, own Kokoro voiceover |
| `make_srt.py` | timed captions (`en` or a JSON list for another language) |
| `make_thumb.py` | 1280x720 thumbnail from a portrait: rembg cutout, green-fringe fix, outline, shadow, big text, price badge. `CROP` selects the part of the source photo |
| `make_infographic.py` | 1600x900 comparison infographic for the article |
| `check_audio_gaps.py` | silence detector; FAIL if a mid-video gap exceeds 1.0 s |

Render settings used: frames piped as raw RGB to ffmpeg, `libx264 -crf 17-18 -preset medium -pix_fmt yuv420p -movflags +faststart`, audio AAC 160 kb/s at 44.1 kHz, 30 fps, 10 worker processes. A 3-minute video renders in about 2 minutes; 13 narration lines take about 1 minute; a Short about 15 to 30 seconds.

Voices: Kokoro has 28 English voices (`af_*` American female, `am_*` American male, `bf_*` British female, `bm_*` British male). Used so far: `af_heart`; the owner finds it robotic and will source a better voice, so keep the TTS step swappable. Samples of all 28 reading the same line are in `~/Videos/voice-samples/`. Kokoro `speed` param can speed a clip slightly (do not exceed about 1.15).

## Optional extras installed during the first video (not needed for the normal workflow)

| Where | What | Notes |
|---|---|---|
| `~/.cache/hb-video-venv/` | Python venv with torch (CPU 2.15), diffusers 0.42.1, transformers, accelerate, rembg | Used for local AI portraits. The workspace venv now has its own rembg, so this one can be removed |
| `~/.cache/huggingface/hub/models--Lykon--dreamshaper-8` | Stable Diffusion model, about 2 GB | About 7 minutes per 576x832 image on this CPU; faces looked cartoonish. Not recommended; safe to delete |
| `~/.u2net/` | rembg background-removal model (about 176 MB), downloaded on first use | Needed by `make_thumb.py` |
| Claude session scratchpad (`/tmp/claude-1000/...`) | the original venv, scripts, Kokoro and Piper models | Temporary: gone after reboot. Piper voices there: `en_US-ryan-high` (robotic), `hi_IN-priyamvada-medium` (Hindi, rejected) |

## System tools available

Python 3.14 (system), Node 18, `/usr/bin/google-chrome` (headless screenshots for previewing site pages at phone width: `google-chrome --headless=new --window-size=390,2600 --screenshot=out.png URL`), VLC, GStreamer (`gst-launch-1.0`), `gh` (GitHub CLI, logged in), `kamal` 2.12.

## Output folders

`~/Videos/` finished videos and thumbnails; `~/Videos/shorts/`, `~/Videos/subtitles/` (SRT and audio experiments), `~/Videos/article-image/` (images uploaded to posts; keep these), `~/Videos/voice-samples/`.

## Not set up (decide before relying on it)

- **Screen recordings** of real tools (recommended for originality; see channel-strategy). Candidate approaches, untested here: `ffmpeg -f x11grab` for desktop capture, or the Chrome extension's `gif_creator` for short browser walkthroughs.
- GPU video effects, motion-graphics software, music or sound-effect library (the videos have no background music; add only royalty-free or self-made audio).
- Any non-English voice engine of acceptable quality.

## Publishing to hypebusted.com (details belong to the article skill)

- A post can hold the video: set its `youtube_video_id` and the page renders the embed above the article.
- Admin is at `/milo` (Avo). Drive it with the Claude in Chrome extension (connect with `/chrome` if tools are missing; the browser must be awake and signed in as the super admin).
- The post body is Action Text. Trix strips `h2`/`h3`, so switch on "Edit as HTML" to paste real HTML. The public page keeps `class` but strips inline `style` and `<table>`. A styled `div.compare` benefit block exists in `app/assets/tailwind/utilities.css`.
- Image upload through the extension: inject a file input, `file_upload` a file from an allowed folder (the session scratchpad works), then `trix-editor.editor.insertFile(file)`; set captions with `editor.composition.updateAttributesForAttachment`.
- **Production loses uploaded images on every deploy** (no storage volume; S3 is planned). Keep local copies and re-upload.
- Deploy path: branch, pull request, merge, GitHub builds the image on `main`, then `kamal deploy --skip-push --version=<full commit sha>`. Pass the version explicitly if the working tree has untracked files.
