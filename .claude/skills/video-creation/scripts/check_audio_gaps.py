"""Report silent gaps in a video's or audio file's soundtrack.

Usage: check_audio_gaps.py FILE [--noise -35] [--min 0.5] [--max-ok 1.0]

Finds every stretch of silence at least --min seconds long. Exits 1 if any gap
(other than the lead-in before the first word and the tail after the last word)
is longer than --max-ok seconds. Viewers read long gaps in a voiceover as "dead
air" or a broken video, so a final render should pass this check.
"""
import argparse
import re
import subprocess
import sys

import imageio_ffmpeg


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file")
    ap.add_argument("--noise", default="-35", help="silence threshold in dB (default -35)")
    ap.add_argument("--min", type=float, default=0.5, help="shortest gap to list, seconds")
    ap.add_argument("--max-ok", type=float, default=1.0, help="longest acceptable mid-video gap, seconds")
    a = ap.parse_args()
    ff = imageio_ffmpeg.get_ffmpeg_exe()
    r = subprocess.run([ff, "-hide_banner", "-nostats", "-i", a.file, "-vn", "-af",
                        "silencedetect=noise=%sdB:d=%s" % (a.noise, a.min), "-f", "null", "-"],
                       capture_output=True, text=True)
    err = r.stderr
    dur = re.search(r"Duration: (\d+):(\d+):([\d.]+)", err)
    total = int(dur.group(1)) * 3600 + int(dur.group(2)) * 60 + float(dur.group(3)) if dur else 0.0
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", err)]
    ends = [(float(e), float(d)) for e, d in re.findall(r"silence_end: ([\d.]+) \| silence_duration: ([\d.]+)", err)]
    gaps = []
    for i, s in enumerate(starts):
        if i < len(ends):
            gaps.append((s, ends[i][0], ends[i][1]))
        else:  # silence runs to the end of the file
            gaps.append((s, total, total - s))
    inner = [g for g in gaps if g[0] > 0.05 and g[1] < total - 0.05]
    print("%s: %.1fs long, %d silent gap(s) >= %.1fs" % (a.file, total, len(gaps), a.min))
    for s, e, d in gaps:
        tag = "lead-in" if s <= 0.05 else ("tail" if e >= total - 0.05 else ("TOO LONG" if d > a.max_ok else "ok"))
        print("  %6.1fs -> %6.1fs  (%.1fs)  %s" % (s, e, d, tag))
    speech = total - sum(g[2] for g in gaps)
    print("speech/sound covers %.0f%% of the file" % (100 * speech / total if total else 0))
    bad = [g for g in inner if g[2] > a.max_ok]
    print("RESULT:", "FAIL - %d gap(s) over %.1fs" % (len(bad), a.max_ok) if bad else "PASS")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
