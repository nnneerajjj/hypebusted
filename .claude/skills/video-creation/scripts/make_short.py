"""Vertical 1080x1920 YouTube Short with voiceover. Worked example of the video-creation skill.

Usage:
  make_short.py preview          -> a PNG per scene in ./short_preview (uses audio/short_durations.json if present)
  make_short.py render OUT.mp4   -> voiceover first, then frames, then mux

Pacing rule (why this file exists in this shape): the narration is synthesized FIRST and every scene is exactly
PAD_IN + clip + PAD_OUT seconds long. The first version of this Short used fixed scene lengths, so 3-5 s clips sat in
6-11 s scenes and 47% of the file was silence. Never size a scene before you know how long its narration is.
"""
import json
import os
import subprocess
import sys
import wave
from multiprocessing import Pool

import numpy as np
from PIL import ImageDraw

import make_video as m
import narration

m.W, m.H = 1080, 1920          # vertical canvas; make_video's helpers read these module globals
W, H, S, FPS = m.W, m.H, m.S, m.FPS
HERE = os.path.dirname(os.path.abspath(__file__))
F, ez, Canvas = m.F, m.ez, m.Canvas
TXT, MUT, ORG, RED, GRN, CARD = m.TXT, m.MUT, m.ORG, m.RED, m.GRN, m.CARD
LEFT, RIGHT = 90, W - 90
PAD_IN, PAD_OUT = 0.2, 0.3     # the only silence between lines
VOICE, SPEED = "af_heart", 1.0

# One narration line per scene. Short = one idea, a hook in the first 2 seconds, a payoff, then the call to action.
VO = [
    "A ninety nine cent domain? Wait until you see the renewal.",
    "Next year it jumps to about twenty two dollars, and it stays there every year after that. "
    "Over five years, that is nearly ninety dollars.",
    "At Cloudflare, a dot com costs eleven dollars and seventeen cents, and renewing costs exactly the same. "
    "Free privacy, free email forwarding, and no surprise renewal bill. That is about thirty three dollars saved.",
    "The full breakdown, with all eight reasons, is in the video. Subscribe for more honest reviews.",
]
# Length each scene's animation was designed for; the animation clock is scaled to the real scene length.
BASE = [4.0, 9.0, 16.0, 8.0]


def scene_hook(c, t):
    c.text(LEFT, 330, "DOMAIN DEALS", F("m", 40, 500), ORG, ez(t, 0.0))
    p = ez(t, 0.2, 0.6)
    c.text(LEFT, 420 + (1 - p) * 24, "$0.99", F("g", 260, 700), GRN, p)
    p = ez(t, 0.9, 0.6)
    c.text(LEFT, 730 + (1 - p) * 20, "domain?", F("g", 110, 700), TXT, p)
    p = ez(t, 1.6, 0.6)
    c.text(LEFT, 900 + (1 - p) * 20, "Check the renewal.", F("s", 74, 500), MUT, p)
    c.pill(LEFT, 1080, "RENEWAL PRICE, AUTO-CHARGED", F("m", 40, 500), RED, ez(t, 2.6, 0.5), h=72, padx=30)


def scene_trap(c, t):
    c.text(LEFT, 330, "THE RENEWAL", F("m", 40, 500), ORG, ez(t, 0.0))
    c.text(LEFT, 400, "Year 1 vs Year 2", F("g", 96, 700), TXT, ez(t, 0.2))
    base, scale = 1450, 36  # px per dollar: $21.99 is about 790 px tall
    c.line([(LEFT, base), (RIGHT, base)], m.LINE, 3, ez(t, 0.4))
    for i, (lab, v, col, t0) in enumerate([("YEAR 1", 0.99, GRN, 0.8), ("YEAR 2", 21.99, RED, 1.6)]):
        x, p = 200 + i * 430, ez(t, t0, 0.8)
        h = max(v * scale * p, 10)
        c.rect(x, base - h, x + 260, base, 14, col, al=1 if p > 0 else 0)
        c.text(x + 130, base - h - 16, "$%.2f" % (0.99 + (v - 0.99) * p), F("g", 80, 700), col, p, "mb")
        c.text(x + 130, base + 36, lab, F("m", 40, 500), MUT, ez(t, t0), "ma")
    c.text(LEFT, 1640, "Every year after that.", F("s", 58, 500), TXT, ez(t, 3.0, 0.6))


def scene_fix(c, t):
    c.text(LEFT, 330, "CLOUDFLARE, AT COST", F("m", 40, 500), ORG, ez(t, 0.0))
    p = ez(t, 0.2, 0.7)
    c.text(LEFT, 420 + (1 - p) * 24, "$11.17", F("g", 280, 700), ORG, p)
    c.text(LEFT, 730, "a year. Register or renew.", F("s", 68, 500), TXT, ez(t, 0.8, 0.6))
    for i, s in enumerate(["No renewal surprises", "Free WHOIS privacy", "Free email forwarding"]):
        p, y = ez(t, 2.0 + i * 1.5, 0.6), 920 + i * 150
        c.card(LEFT, y, RIGHT, y + 120, p, r=28)
        c.check(LEFT + 70, y + 60, 34, GRN, p, CARD)
        c.text(LEFT + 130, y + 60, s, F("s", 54, 600), TXT, p, "lm", CARD)
    c.text(LEFT, 1440, "Same price in year five.", F("g", 64, 700), TXT, ez(t, 7.0, 0.6))


def scene_cta(c, t):
    p = ez(t, 0.0, 0.7)
    c.text(LEFT, 470 + (1 - p) * 20, "Full breakdown", F("g", 112, 700), TXT, p)
    c.text(LEFT, 610, "8 reasons, ranked", F("g", 80, 700), ORG, ez(t, 0.6, 0.6))
    c.text(LEFT, 790, "Link in the description", F("s", 60, 500), MUT, ez(t, 1.4, 0.6))
    p = ez(t, 2.6, 0.6)
    c.rect(LEFT, 1030, RIGHT, 1190, 40, RED, al=p)
    c.text(W / 2, 1110, "SUBSCRIBE", F("g", 84, 700), (255, 255, 255), p, "mm", RED)
    p = ez(t, 3.6, 0.6)
    c.text(LEFT, 1300, "More honest reviews:", F("s", 54, 400), MUT, p)
    c.text(LEFT, 1370, "hypebusted.com", F("g", 84, 700), ORG, p)


SCENES = [scene_hook, scene_trap, scene_fix, scene_cta]
DJ = os.path.join(HERE, "audio", "short_durations.json")
DURS = STARTS = TOTAL = NFRAMES = None


def plan():
    """(Re)compute scene timing from the clip lengths on disk, or from BASE before any audio exists."""
    global DURS, STARTS, TOTAL, NFRAMES
    clips = json.load(open(DJ)) if os.path.exists(DJ) else None
    DURS = [PAD_IN + c + PAD_OUT for c in clips] if clips else list(BASE)
    STARTS = np.cumsum([0] + DURS[:-1]).tolist()
    TOTAL = sum(DURS)
    NFRAMES = round(TOTAL * FPS)


plan()  # also runs when a worker process imports this module (Python 3.14 starts workers fresh, not forked)


def frame(n):
    T = n / FPS
    i = 0
    while i < len(SCENES) - 1 and T >= STARTS[i + 1]:
        i += 1
    t = T - STARTS[i]
    c = Canvas()
    SCENES[i](c, t * BASE[i] / DURS[i])
    im = c.im.reduce(S)
    d = ImageDraw.Draw(im)
    d.rectangle((0, H - 10, W, H), fill=(26, 30, 39))
    d.rectangle((0, H - 10, round(W * T / TOTAL), H), fill=ORG)
    return im


def frame_bytes(n):
    return frame(n).tobytes()


def voiceover(out_wav):
    """Synthesize every line, record clip lengths, and lay the clips back to back (PAD_IN before, PAD_OUT after)."""
    from kokoro_onnx import Kokoro
    k = Kokoro(os.path.join(HERE, "kokoro", "kokoro-v1.0.onnx"), os.path.join(HERE, "kokoro", "voices-v1.0.bin"))
    clips, sr = [], 24000
    for text in VO:
        a, sr = k.create(text, voice=VOICE, speed=SPEED, lang="en-us")
        clips.append(narration.normalize_and_trim(a, sr))
    os.makedirs(os.path.dirname(DJ), exist_ok=True)
    json.dump([len(a) / sr for a in clips], open(DJ, "w"))
    plan()
    track = np.zeros(int(TOTAL * sr) + sr, dtype=np.int16)
    for a, st in zip(clips, STARTS):
        k0 = int((st + PAD_IN) * sr)
        track[k0:k0 + len(a)] = a
    with wave.open(out_wav, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(track.tobytes())


def main():
    plan()
    if sys.argv[1] == "preview":
        os.makedirs(os.path.join(HERE, "short_preview"), exist_ok=True)
        for i, st in enumerate(STARTS):
            frame(round((st + DURS[i] * 0.6) * FPS)).save(os.path.join(HERE, "short_preview", "s%d.png" % i))
        return
    import imageio_ffmpeg
    ff_exe = imageio_ffmpeg.get_ffmpeg_exe()
    silent, wav, out = os.path.join(HERE, "short_silent.mp4"), os.path.join(HERE, "audio", "short_vo.wav"), sys.argv[2]
    voiceover(wav)  # also re-plans DURS/STARTS/TOTAL/NFRAMES from the real clip lengths, before the workers fork
    cmd = [ff_exe, "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", "%dx%d" % (W, H),
           "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
           "-movflags", "+faststart", silent]
    ff = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    with Pool(10) as pool:
        for b in pool.imap(frame_bytes, range(NFRAMES), chunksize=4):
            ff.stdin.write(b)
    ff.stdin.close()
    if ff.wait():
        sys.exit(1)
    sys.exit(subprocess.call([ff_exe, "-y", "-loglevel", "error", "-i", silent, "-i", wav, "-c:v", "copy", "-c:a", "aac",
                              "-b:a", "160k", "-ar", "44100", "-shortest", "-movflags", "+faststart", out]))


if __name__ == "__main__":
    main()
