"""Write a timed .srt subtitle file aligned to the video's narration.

Usage:
  make_srt.py en OUT.srt            English captions from narration.LINES
  make_srt.py TEXTS.json OUT.srt    any language: a JSON list with one string per scene (same count as narration.LINES)

Cue times come from audio/durations.json (the narration clip lengths) and make_video.DURS (scene lengths), so the
captions follow the voiceover. Long sentences are split into short cues so they stay readable on a phone.
Upload in YouTube Studio > Subtitles > the language > Upload file > "With timing".
"""
import json
import os
import re
import sys

import make_video as m
import narration

HERE = os.path.dirname(os.path.abspath(__file__))
MAX_CHARS = 80      # split longer sentences so each cue fits on a phone
TAIL_GAP = 0.1      # a cue ends slightly before its narration clip ends


def ts(sec):
    ms = round(sec * 1000)
    h, ms = divmod(ms, 3600_000)
    mi, ms = divmod(ms, 60_000)
    s, ms = divmod(ms, 1000)
    return "%02d:%02d:%02d,%03d" % (h, mi, s, ms)


def split_cues(text):
    """Sentences first, then break long sentences at the comma nearest the middle."""
    parts = [p.strip() for p in re.split(r"(?<=[।?.!])\s+", text) if p.strip()]
    out = []
    for p in parts:
        while len(p) > MAX_CHARS:
            cands = [i for i, c in enumerate(p) if c == "," and 15 < i < len(p) - 15]
            if not cands:
                break
            cut = min(cands, key=lambda i: abs(i - len(p) / 2))
            out.append(p[: cut + 1].strip())
            p = p[cut + 1:].strip()
        out.append(p)
    return out


def main(src, out):
    texts = narration.LINES if src == "en" else json.load(open(src, encoding="utf-8"))
    durs = json.load(open(os.path.join(HERE, "audio", "durations.json")))
    assert len(texts) == len(durs) == len(m.DURS), (len(texts), len(durs), len(m.DURS))
    cues, t0 = [], 0.0
    for text, d, scene_len in zip(texts, durs, m.DURS):
        start, end = t0 + narration.LEAD, t0 + narration.LEAD + d - TAIL_GAP
        parts = split_cues(text)
        weights = [len(p) for p in parts]
        cur = start
        for p, w in zip(parts, weights):
            span = (end - start) * w / sum(weights)
            cues.append((cur, cur + span, p))
            cur += span
        t0 += scene_len
    with open(out, "w", encoding="utf-8") as f:
        for i, (a, b, text) in enumerate(cues, 1):
            f.write("%d\n%s --> %s\n%s\n\n" % (i, ts(a), ts(b), text))
    print(out, len(cues), "cues, last ends", ts(cues[-1][1]))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
