import json, os, sys, wave
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
LINES = [
 "Looking for one place to buy your domain name? Here is every advantage of registering at Cloudflare, ranked from most to least important.",
 "First, the trap. Many registrars advertise a tiny first-year price, like ninety-nine cents. Then year two arrives, and the renewal is around twenty-two dollars. Every year after that.",
 "And that is only one trick. Some charge extra to keep your home address private. Some pre-tick add-ons in your cart. Email forwarding, S S L, and so-called protection bundles become paid upgrades. And renewal prices keep creeping up.",
 "Number one: at-cost pricing. Cloudflare charges exactly what the registry and eye-can charge them, with zero markup. For a dot com, that is eleven dollars and seventeen cents a year, whether you register or renew.",
 "Number two: no surprise renewal fees. Year five costs the same as year one. Over five years, that is about fifty-six dollars, against roughly eighty-nine at a typical promo registrar.",
 "Number three: free who-is privacy. Your name, address, phone and email are redacted from the public record, at no cost. Elsewhere, this can be a paid add-on.",
 "Number four: free email forwarding. Create as many addresses on your domain as you like, and they all arrive in the inbox you already use. Note that this is forwarding, not a hosted mailbox.",
 "Number five: a global cache, built in. Your pages and assets are served from Cloudflare's edge, close to each visitor, with unmetered bandwidth on the free plan.",
 "Number six: a smaller A W S bill. If your images live in an S three bucket, Amazon charges for every gigabyte that leaves it. With Cloudflare caching those images, most requests never reach Amazon. In this example, ninety dollars a month drops to under five.",
 "Number seven: security included. A free S S L certificate, dee-doss protection, and one-click D N S sec. All at no extra cost.",
 "Number eight: simple D N S setup. Your registrar and D N S live in one dashboard. Add a record, save, and it is live within seconds. Mail records are even added for you.",
 "So, to recap. Fair pricing, no renewal surprises, free privacy, free email forwarding, a global cache, lower A W S costs, built-in security, and simple D N S. Just remember, your domain has to use Cloudflare's nameservers.",
 "That's the full picture. If this helped, subscribe to our channel, and visit Hype Busted dot com for more honest reviews. And for the record: we are not affiliated with Cloudflare. They sell domains at cost and make no profit on them, so there is no affiliate program. We earn nothing if you buy a domain there.",
]
# Silence kept around each clip. Scene length = LEAD + clip + TAIL, so these ARE the pauses viewers hear.
LEAD, TAIL = 0.2, 0.3

VOICE, SPEED = "af_heart", 1.0

def normalize_and_trim(a, sr, keep=0.04):
    """Peak-normalize to -1 dB and cut the silence the voice model leaves at both ends of a clip.
    Without the trim, every clip adds 0.1-0.3 s of hidden silence and the pauses between lines vary."""
    a = (a / max(abs(a).max(), 1e-6) * 0.89 * 32767).astype(np.int16)
    loud = np.flatnonzero(abs(a) > 0.01 * 32767)
    if len(loud):
        k = int(keep * sr)
        a = a[max(loud[0] - k, 0): loud[-1] + k]
    return a


def synth():
    from kokoro_onnx import Kokoro
    k = Kokoro(os.path.join(HERE, "kokoro", "kokoro-v1.0.onnx"), os.path.join(HERE, "kokoro", "voices-v1.0.bin"))
    durs = []
    for i, s in enumerate(LINES):
        a, sr = k.create(s, voice=VOICE, speed=SPEED, lang="en-us")
        a = normalize_and_trim(a, sr)
        with wave.open(os.path.join(HERE, "audio", "%02d.wav" % i), "wb") as w:
            w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(a.tobytes())
        durs.append(len(a) / sr)
    json.dump(durs, open(os.path.join(HERE, "audio", "durations.json"), "w"))
    return durs

def build_track(scene_durs, out):
    """Lay each clip LEAD seconds after its scene starts."""
    with wave.open(os.path.join(HERE, "audio", "00.wav")) as w:
        sr = w.getframerate()
    track = np.zeros(int(sum(scene_durs) * sr) + sr, dtype=np.int16)
    t0 = 0.0
    for i, d in enumerate(scene_durs):
        with wave.open(os.path.join(HERE, "audio", "%02d.wav" % i)) as w:
            a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
        k = int((t0 + LEAD) * sr)
        track[k:k + len(a)] = a
        t0 += d
    with wave.open(out, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(track.tobytes())

if __name__ == "__main__":
    for i, d in enumerate(synth()):
        print(i, round(d, 2))
