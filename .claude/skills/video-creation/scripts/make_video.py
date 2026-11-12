"""Renders the "One stop for buying your domain name" explainer (1920x1080, 30 fps) with voiceover.

Worked example of the video-creation skill: copy this file for a new video and replace the scenes, the SCENES list
and the constants at the top (prices etc.). Keep scene length tied to the narration (see DURS below).

Usage:
  make_video.py preview            -> one PNG per scene in ./preview
  make_video.py render OUT.mp4     -> full video
"""
import math
import os
import subprocess
import sys
from multiprocessing import Pool

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H, S, FPS = 1920, 1080, 2, 30

BG = (12, 14, 19)
CARD = (22, 26, 34)
LINE = (44, 51, 64)
TXT = (242, 244, 247)
MUT = (158, 168, 182)
DIM = (100, 110, 126)
CF_PRICE, CF_PRICE_S = 11.17, "$11.17"
ORG = (246, 130, 31)
RED = (240, 82, 75)
GRN = (61, 214, 140)

FONT_FILES = {"g": "space-grotesk.ttf", "s": "dm-sans.ttf", "m4": "dm-mono-400.ttf", "m5": "dm-mono-500.ttf"}
_fonts = {}


def F(kind, size, weight=400):
    key = (kind, size, weight)
    if key not in _fonts:
        if kind == "m":
            f = ImageFont.truetype(os.path.join(HERE, "fonts", FONT_FILES["m5" if weight >= 500 else "m4"]), size * S)
        else:
            f = ImageFont.truetype(os.path.join(HERE, "fonts", FONT_FILES[kind]), size * S)
            f.set_variation_by_axes([weight])
        _fonts[key] = f
    return _fonts[key]


def tw(s, f):
    return f.getlength(s) / S


def fit(kind, size, weight, s, maxw):
    while tw(s, F(kind, size, weight)) > maxw and size > 20:
        size -= 2
    return F(kind, size, weight)


def clamp(x, a=0.0, b=1.0):
    return max(a, min(b, x))


def ez(t, t0, dur=0.5):
    """Ease-out cubic progress of an animation starting at t0."""
    p = clamp((t - t0) / dur)
    return 1 - (1 - p) ** 3


def mix(col, al, on=BG):
    al = clamp(al)
    return tuple(round(on[i] + (col[i] - on[i]) * al) for i in range(3))


_bg = None


def background():
    global _bg
    if _bg is None:
        im = Image.new("RGB", (W * S, H * S), BG)
        d = ImageDraw.Draw(im)
        dot = (22, 25, 33)
        for x in range(48, W, 48):
            for y in range(48, H, 48):
                d.ellipse((x * S - 3, y * S - 3, x * S + 3, y * S + 3), fill=dot)
        small = Image.new("L", (W // 4, H // 4), 0)
        ImageDraw.Draw(small).ellipse((W // 4 - 170, -190, W // 4 + 150, 130), fill=46)
        mask = small.filter(ImageFilter.GaussianBlur(60)).resize(im.size, Image.BICUBIC)
        im = Image.composite(Image.new("RGB", im.size, ORG), im, mask)
        _bg = im
    return _bg


class Canvas:
    def __init__(self):
        self.im = background().copy()
        self.d = ImageDraw.Draw(self.im)

    def text(self, x, y, s, f, col=TXT, al=1.0, anchor="la", on=BG):
        if al > 0.02 and s:
            self.d.text((x * S, y * S), s, font=f, fill=mix(col, al, on), anchor=anchor)

    def rect(self, x0, y0, x1, y1, r=24, fill=None, outline=None, w=2, al=1.0, on=BG):
        if al <= 0.02 or x1 - x0 < 1 or y1 - y0 < 1:
            return
        r = min(r, (x1 - x0) / 2, (y1 - y0) / 2)
        self.d.rounded_rectangle(
            (x0 * S, y0 * S, x1 * S, y1 * S), radius=r * S,
            fill=mix(fill, al, on) if fill else None,
            outline=mix(outline, al, on) if outline else None, width=w * S)

    def card(self, x0, y0, x1, y1, al=1.0, outline=LINE, fill=CARD, r=24):
        self.rect(x0, y0, x1, y1, r, fill, outline, 2, al)

    def line(self, pts, col, w=4, al=1.0, on=BG):
        if al > 0.02:
            self.d.line([(x * S, y * S) for x, y in pts], fill=mix(col, al, on), width=round(w * S), joint="curve")

    def dot(self, x, y, r, col, al=1.0, on=BG):
        if al > 0.02:
            self.d.ellipse(((x - r) * S, (y - r) * S, (x + r) * S, (y + r) * S), fill=mix(col, al, on))

    def check(self, x, y, size, col=GRN, al=1.0, on=BG):
        self.dot(x, y, size, mix(col, 0.18, on), al, on)
        k = size * 0.45
        self.line([(x - k, y), (x - k * 0.25, y + k * 0.7), (x + k, y - k * 0.7)], col, size * 0.2, al, on)

    def cross(self, x, y, size, col=RED, al=1.0, on=BG):
        self.dot(x, y, size, mix(col, 0.18, on), al, on)
        k = size * 0.4
        self.line([(x - k, y - k), (x + k, y + k)], col, size * 0.2, al, on)
        self.line([(x - k, y + k), (x + k, y - k)], col, size * 0.2, al, on)

    def arrow(self, x0, y0, x1, y1, col, w=4, al=1.0, head=14):
        self.line([(x0, y0), (x1, y1)], col, w, al)
        a = math.atan2(y1 - y0, x1 - x0)
        for da in (2.6, -2.6):
            self.line([(x1, y1), (x1 + head * math.cos(a + da), y1 + head * math.sin(a + da))], col, w, al)

    def pill(self, x, y, s, f, col, al=1.0, on=BG, padx=18, h=44):
        w = tw(s, f) + padx * 2
        self.rect(x, y, x + w, y + h, h / 2, mix(col, 0.16, on), col, 2, al, on)
        self.text(x + padx, y + h / 2, s, f, col, al, "lm", on)
        return w


def head(c, t, label, title, sub, rank=None):
    c.text(140, 92, label, F("m", 26, 500), ORG, ez(t, 0.0))
    p = ez(t, 0.1, 0.6)
    y = 142 + (1 - p) * 22
    x = 140
    if rank:
        f = F("g", 92, 700)
        c.text(x, y, rank, f, ORG, p)
        x += tw(rank, f) + 34
    c.text(x, y, title, fit("g", 92, 700, title, W - 140 - x), TXT, p)
    p = ez(t, 0.45, 0.6)
    c.text(140, 276 + (1 - p) * 16, sub, fit("s", 38, 400, sub, W - 280), MUT, p)


def footnote(c, t, s, t0):
    c.text(140, 968, s, F("s", 26, 400), DIM, ez(t, t0))


# ---------------------------------------------------------------- scenes

def sc_title(c, t):
    c.text(140, 300, "DOMAIN BUYING GUIDE", F("m", 30, 500), ORG, ez(t, 0.1))
    f = F("g", 132, 700)
    for i, s in enumerate(["One stop for buying", "your domain name"]):
        p = ez(t, 0.3 + i * 0.25, 0.7)
        c.text(140, 370 + i * 150 + (1 - p) * 30, s, f, TXT, p)
    p = ez(t, 1.0, 0.8)
    c.rect(140, 700, 140 + 420 * p, 708, 4, ORG, al=1 if p > 0 else 0)
    p = ez(t, 1.4, 0.6)
    c.text(140, 750 + (1 - p) * 16, "Every advantage of registering at cloudflare.com, ranked.", F("s", 44, 400), MUT, p)


def sc_trap(c, t):
    head(c, t, "WHAT OTHER REGISTRARS DO", "The first-year teaser", "The headline price is real. It just does not last.")
    p = ez(t, 1.0)
    c.card(140, 390, 880, 880, p)
    c.text(190, 436, "YEAR 1", F("m", 28, 500), MUT, p, on=CARD)
    c.text(190, 500, "$0.99", F("g", 180, 700), GRN, p, on=CARD)
    c.pill(190, 780, "LIMITED-TIME OFFER!", F("m", 24, 500), GRN, ez(t, 1.5), CARD)

    p = ez(t, 2.6)
    c.arrow(910, 635, 910 + 100 * p, 635, MUT, 5, p, 18)

    p = ez(t, 3.0)
    c.card(1040, 390, 1780, 880, p, outline=mix(RED, 0.6, CARD))
    c.text(1090, 436, "YEAR 2, AND EVERY YEAR AFTER", F("m", 28, 500), MUT, p, on=CARD)
    v = 0.99 + (21.99 - 0.99) * ez(t, 3.2, 1.6)
    c.text(1090, 500, "$%.2f" % v, F("g", 180, 700), RED, p, on=CARD)
    c.pill(1090, 780, "RENEWAL PRICE, AUTO-CHARGED", F("m", 24, 500), RED, ez(t, 5.0), CARD)
    footnote(c, t, "A 22x jump. You keep a domain for years, so the renewal is the real price.  (Typical promo pricing, illustrative.)", 5.6)


TRICKS = [
    ("Teaser price, steep renewal", "Year one is the bait. Renewal is 2x or more."),
    ("Paid WHOIS privacy", "Hiding your home address costs extra at some."),
    ("Pre-checked cart extras", "Add-ons you never asked for, already ticked."),
    ("Email costs extra", "Forwarding and mailboxes sold as upgrades."),
    ("SSL and \"protection\" upsells", "Paying for things that are free elsewhere."),
    ("Creeping renewal hikes", "Markup stacked on every registry increase."),
]


def sc_tricks(c, t):
    head(c, t, "WHAT OTHER REGISTRARS DO", "The usual tricks", "Not every registrar does all of these. Many do some.")
    for i, (a, b) in enumerate(TRICKS):
        col, row = i % 2, i // 2
        x0, y0 = 140 + col * 830, 390 + row * 180
        p = ez(t, 1.0 + i * 1.1)
        y0 += (1 - p) * 20
        c.card(x0, y0, x0 + 790, y0 + 150, p)
        c.cross(x0 + 70, y0 + 75, 30, RED, p, CARD)
        c.text(x0 + 130, y0 + 30, a, F("g", 40, 700), TXT, p, on=CARD)
        c.text(x0 + 130, y0 + 88, b, F("s", 28, 400), MUT, p, on=CARD)


def sc_price(c, t):
    head(c, t, "WHY CLOUDFLARE   1 / 8", "At-cost pricing", "You pay what the registry charges Cloudflare. Nothing on top.", "#1")
    items = [("REGISTRY FEE", "at cost", TXT), ("ICANN FEE", "cents", TXT), ("CLOUDFLARE MARKUP", "$0", ORG)]
    x = 140
    for i, (lab, val, col) in enumerate(items):
        p = ez(t, 1.0 + i * 0.7)
        c.card(x, 420, x + 340, 660, p, outline=ORG if col == ORG else LINE)
        c.text(x + 34, 452, lab, F("m", 24, 500), MUT, p, on=CARD)
        c.text(x + 34, 520, val, F("g", 84, 700), col, p, on=CARD)
        if i < 2:
            c.text(x + 340 + 35, 540, "+", F("g", 72, 500), MUT, ez(t, 1.4 + i * 0.7), "mm")
        x += 410
    c.text(x - 35, 540, "=", F("g", 72, 500), MUT, ez(t, 3.2), "mm")
    p = ez(t, 3.4)
    c.card(x, 420, 1780, 660, p, outline=ORG, fill=mix(ORG, 0.12, CARD))
    on = mix(ORG, 0.12, CARD)
    c.text(x + 34, 452, "YOUR PRICE, .COM", F("m", 24, 500), MUT, p, on=on)
    c.text(x + 34, 524, CF_PRICE_S, F("g", 78, 700), TXT, p, on=on)
    c.text(x + 34 + tw(CF_PRICE_S, F("g", 78, 700)) + 12, 576, "/yr", F("s", 32, 400), MUT, p, on=on)
    for i, s in enumerate(["Same price to register, renew or transfer in", "No intro discount to claw back later", "No paid tiers, no checkout upsells"]):
        p = ez(t, 4.4 + i * 0.5)
        c.check(164, 760 + i * 68, 22, GRN, p)
        c.text(210, 760 + i * 68, s, F("s", 36, 400), TXT, p, "lm")


def sc_renew(c, t):
    head(c, t, "WHY CLOUDFLARE   2 / 8", "No surprise renewal fees", "Year five costs the same as year one. Only real registry changes pass through.", "#2")
    base, k = 880, 17.0
    c.line([(140, base), (1180, base)], LINE, 2, ez(t, 0.8))
    for i in range(5):
        gx = 190 + i * 200
        p = ez(t, 1.1 + i * 0.45, 0.7)
        cf, ot = CF_PRICE, (0.99 if i == 0 else 21.99)
        c.rect(gx, base - cf * k * p, gx + 70, base, 8, ORG, al=1 if p > 0 else 0)
        c.rect(gx + 82, base - max(ot * k * p, 6), gx + 152, base, 8 if i else 3, RED, al=1 if p > 0 else 0)
        c.text(gx + 35, base - cf * k * p - 12, CF_PRICE_S, F("m", 22, 500), ORG, p, "mb")
        c.text(gx + 117, base - ot * k * p - 12, "$%.2f" % ot, F("m", 22, 500), RED, p, "mb")
        c.text(gx + 76, base + 20, "Year %d" % (i + 1), F("s", 26, 400), MUT, p, "ma")
    p = ez(t, 0.9)
    c.dot(152, 420, 10, ORG, p)
    c.text(176, 420, "Cloudflare", F("s", 28, 500), TXT, p, "lm")
    c.dot(372, 420, 10, RED, p)
    c.text(396, 420, "Typical promo registrar", F("s", 28, 500), TXT, p, "lm")

    p = ez(t, 4.0)
    c.card(1260, 400, 1780, 920, p)
    c.text(1300, 436, "5-YEAR TOTAL, ONE .COM", F("m", 24, 500), MUT, p, on=CARD)
    p = ez(t, 4.5)
    c.text(1300, 490, "~$%d" % round(CF_PRICE * 5), F("g", 110, 700), ORG, p, on=CARD)
    c.text(1300, 616, "Cloudflare", F("s", 30, 400), MUT, p, on=CARD)
    p = ez(t, 5.3)
    c.line([(1300, 676), (1740, 676)], LINE, 2, p, CARD)
    c.text(1300, 700, "~$89", F("g", 110, 700), RED, p, on=CARD)
    c.text(1300, 826, "Typical promo registrar,", F("s", 30, 400), MUT, p, on=CARD)
    c.text(1300, 864, "before any privacy add-on", F("s", 30, 400), MUT, p, on=CARD)
    footnote(c, t, "Cloudflare .com price as of November 2026. Promo registrar prices are illustrative.", 6.0)


WHOIS = [("Registrant Name", "Jane Doe"), ("Street", "12 Main Street, Springfield"), ("Phone", "+1 555 0100"), ("Email", "jane@example.com")]


def sc_privacy(c, t):
    head(c, t, "WHY CLOUDFLARE   3 / 8", "Free WHOIS privacy", "Your name, address and phone stay out of the public record. Included, for good.", "#3")
    p = ez(t, 0.9)
    c.card(140, 400, 1180, 900, p, fill=(16, 19, 25))
    on = (16, 19, 25)
    for i, col in enumerate([RED, (240, 190, 70), GRN]):
        c.dot(182 + i * 30, 440, 8, col, p * 0.8, on)
    cmd = "$ whois yourdomain.com"
    c.text(180, 486, cmd[: int(len(cmd) * clamp((t - 1.0) / 0.9))], F("m", 30, 500), TXT, p, on=on)
    for i, (k, v) in enumerate(WHOIS):
        y = 570 + i * 74
        p = ez(t, 2.0 + i * 0.2)
        c.text(180, y, k + ":", F("m", 30, 400), MUT, p, on=on)
        r = ez(t, 3.4 + i * 0.5, 0.4)
        if r < 1:
            c.text(520, y, v, F("m", 30, 400), TXT, p * (1 - r), on=on)
        if r > 0:
            c.rect(510, y - 6, 510 + 440 * r, y + 44, 8, mix(ORG, 0.16, on), al=1, on=on)
            c.text(524, y, "REDACTED FOR PRIVACY", F("m", 30, 500), ORG, ez(t, 3.6 + i * 0.5, 0.3), on=mix(ORG, 0.16, on))
    p = ez(t, 5.2)
    c.text(1280, 440, "$0", F("g", 220, 700), ORG, p)
    c.text(1284, 700, "Included with every domain.", F("s", 34, 500), TXT, p)
    p = ez(t, 5.8)
    c.text(1284, 760, "Elsewhere it can be a paid", F("s", 30, 400), MUT, p)
    c.text(1284, 800, "add-on of around $10 a year.", F("s", 30, 400), MUT, p)


ADDRS = ["hello@yourdomain.com", "sales@yourdomain.com", "support@yourdomain.com", "billing@yourdomain.com", "*@yourdomain.com"]


def sc_email(c, t):
    head(c, t, "WHY CLOUDFLARE   4 / 8", "Free email forwarding", "Create addresses on your domain. They land in the inbox you already use.", "#4")
    f = F("m", 30, 500)
    tx, ty = 1240, 620
    for i, a in enumerate(ADDRS):
        y = 400 + i * 96
        p = ez(t, 0.9 + i * 0.35)
        last = i == len(ADDRS) - 1
        c.rect(140, y, 720, y + 70, 16, CARD, ORG if last else LINE, 2, p)
        c.text(172, y + 35, a, f, ORG if last else TXT, p, "lm", CARD)
        if last:
            c.text(740, y + 35, "catch-all", F("s", 26, 400), MUT, p, "lm")
        q = ez(t, 2.8 + i * 0.15, 0.6)
        x0, y0 = 730 if not last else 870, y + 35
        x1, y1 = x0 + (tx - 20 - x0) * q, y0 + (ty - y0) * q
        c.line([(x0, y0), (x1, y1)], LINE, 3, 1 if q > 0 else 0)
        if q >= 1:
            u = ((t - 3.4) * 0.6 + i * 0.21) % 1
            c.dot(x0 + (tx - 20 - x0) * u, y0 + (ty - y0) * u, 8, ORG)
    p = ez(t, 2.6)
    c.card(tx, 520, 1780, 720, p, outline=ORG)
    c.text(tx + 40, 556, "YOUR EXISTING INBOX", F("m", 24, 500), MUT, p, on=CARD)
    c.text(tx + 40, 610, "you@gmail.com", F("g", 54, 700), TXT, p, on=CARD)
    for i, (s, col) in enumerate([("$0", ORG), ("Unlimited addresses with catch-all", TXT)]):
        p = ez(t, 4.6 + i * 0.5)
        c.check(tx + 22, 790 + i * 62, 20, GRN, p)
        c.text(tx + 62, 790 + i * 62, s, F("s", 32, 500), col, p, "lm")
    footnote(c, t, "Forwarding only: Cloudflare routes the mail, it does not host mailboxes.", 5.8)


def node(c, x, y, w, h, label, title, p, outline=LINE):
    c.card(x, y, x + w, y + h, p, outline=outline)
    c.text(x + w / 2, y + 44, label, F("m", 22, 500), MUT, p, "mm", CARD)
    c.text(x + w / 2, y + h / 2 + 16, title, fit("g", 42, 700, title, w - 40), TXT, p, "mm", CARD)


def sc_cache(c, t):
    head(c, t, "WHY CLOUDFLARE   5 / 8", "A global cache, built in", "Pages and assets are served from Cloudflare's edge, close to every visitor.", "#5")
    y, h = 430, 200
    node(c, 140, y, 380, h, "WORLDWIDE", "Visitors", ez(t, 0.9))
    node(c, 770, y, 380, h, "CLOUDFLARE EDGE", "Cache", ez(t, 1.3), ORG)
    node(c, 1400, y, 380, h, "ORIGIN", "Your server", ez(t, 1.7))
    my = y + h / 2
    p = ez(t, 2.0)
    c.line([(540, my), (750, my)], ORG, 3, p)
    c.line([(1170, my), (1380, my)], LINE, 3, p)
    if t > 2.4:
        for i in range(4):
            u = ((t - 2.4) * 0.9 + i * 0.25) % 1
            c.dot(540 + 210 * (1 - abs(2 * u - 1)), my, 9, ORG)
        u = clamp((t - 3.0) / 1.2)
        if 0 < u < 1:
            c.dot(1170 + 210 * (1 - abs(2 * u - 1)), my, 9, MUT)
    c.pill(590, my - 80, "CACHE HIT", F("m", 22, 500), GRN, ez(t, 2.6))
    c.text(1275, my - 58, "rarely", F("m", 22, 500), DIM, ez(t, 3.0), "mm")
    rows = [("Unmetered bandwidth", "No per-GB charge for traffic served by the CDN."),
            ("Free plan", "Caching is on by default for static assets."),
            ("Faster pages", "Less distance to travel, less load on your server.")]
    for i, (a, b) in enumerate(rows):
        p = ez(t, 4.0 + i * 0.5)
        x = 140 + i * 560
        c.check(x + 22, 742, 22, GRN, p)
        c.text(x + 62, 742, a, F("g", 36, 700), TXT, p, "lm")
        c.text(x, 790, b, F("s", 25, 400), MUT, p)


def sc_aws(c, t):
    head(c, t, "WHY CLOUDFLARE   6 / 8", "A smaller AWS bill for images", "Keep images in an S3 bucket. Cloudflare caches them, so most requests never reach AWS.", "#6")
    y, h = 410, 150
    node(c, 140, y, 300, h, "AWS", "S3 bucket", ez(t, 0.9))
    node(c, 560, y, 300, h, "CLOUDFLARE", "Cache", ez(t, 1.2), ORG)
    node(c, 980, y, 300, h, "WORLDWIDE", "Visitors", ez(t, 1.5))
    my = y + h / 2
    p = ez(t, 1.8)
    c.line([(455, my), (545, my)], LINE, 3, p)
    c.line([(875, my), (965, my)], ORG, 3, p)
    if t > 2.2:
        for i in range(3):
            u = ((t - 2.2) * 1.1 + i * 0.33) % 1
            c.dot(875 + 90 * u, my, 8, ORG)
        u = clamp((t - 2.6) / 1.0)
        if 0 < u < 1:
            c.dot(455 + 90 * u, my, 8, MUT)
    c.text(500, my + 40, "paid", F("m", 22, 500), RED, ez(t, 2.4), "mm")
    c.text(500, my + 68, "egress", F("m", 22, 500), RED, ez(t, 2.4), "mm")
    c.text(920, my + 40, "free", F("m", 22, 500), GRN, ez(t, 2.4), "mm")
    c.text(920, my + 68, "egress", F("m", 22, 500), GRN, ez(t, 2.4), "mm")

    c.text(140, 640, "EXAMPLE: 1,000 GB OF IMAGE TRAFFIC A MONTH", F("m", 24, 500), MUT, ez(t, 3.4))
    rows = [("Served straight from S3", 90.0, "~$90", RED, 3.9), ("Behind Cloudflare, 95% cached", 4.5, "~$4.50", ORG, 5.0)]
    for i, (lab, val, s, col, t0) in enumerate(rows):
        yy = 700 + i * 110
        p = ez(t, t0, 0.8)
        c.text(140, yy + 30, lab, F("s", 32, 500), TXT, ez(t, t0), "lm")
        c.rect(700, yy, 700 + max(val / 90 * 780 * p, 8), yy + 60, 10, col, al=1 if p > 0 else 0)
        c.text(700 + max(val / 90 * 780 * p, 8) + 24, yy + 30, s, F("g", 44, 700), col, p, "lm")
    c.card(1380, 400, 1780, 570, ez(t, 6.2), outline=ORG)
    c.text(1410, 430, "SAVED", F("m", 22, 500), MUT, ez(t, 6.2), on=CARD)
    c.text(1410, 464, "~95%", F("g", 76, 700), GRN, ez(t, 6.2), on=CARD)
    footnote(c, t, "Example at about $0.09 per GB S3 data transfer out. Cache hit rate and your numbers will vary.", 6.6)


def sc_security(c, t):
    head(c, t, "WHY CLOUDFLARE   7 / 8", "Security included", "The basics other registrars sell as upgrades are switched on for free.", "#7")
    items = [("Free SSL certificate", ["HTTPS for your domain,", "issued and renewed for you."]),
             ("DDoS protection", ["Unmetered, on every plan,", "including the free one."]),
             ("One-click DNSSEC", ["Stops forged DNS answers.", "No manual key copying."])]
    for i, (a, bs) in enumerate(items):
        x = 140 + i * 560
        p = ez(t, 1.0 + i * 0.7)
        yo = (1 - p) * 20
        c.card(x, 420 + yo, x + 520, 820 + yo, p)
        c.check(x + 74, 500 + yo, 36, GRN, p, CARD)
        c.pill(x + 400, 478 + yo, "$0", F("m", 26, 500), ORG, p, CARD)
        c.text(x + 40, 580 + yo, a, fit("g", 46, 700, a, 440), TXT, p, on=CARD)
        for j, b in enumerate(bs):
            c.text(x + 40, 660 + yo + j * 42, b, F("s", 30, 400), MUT, p, on=CARD)
    p = ez(t, 3.6)
    c.text(140, 890 + (1 - p) * 16, "Extra cost for all three:", F("s", 40, 400), MUT, p, "lm")
    c.text(140 + tw("Extra cost for all three: ", F("s", 40, 400)), 890 + (1 - p) * 16, "$0", F("g", 56, 700), ORG, p, "lm")


DNS = [("A", "@", "203.0.113.10", True), ("CNAME", "www", "yourdomain.com", True),
       ("MX", "@", "route1.mx.cloudflare.net", False), ("TXT", "@", "v=spf1 include:_spf.mx.cloudflare.net ~all", False)]


def sc_dns(c, t):
    head(c, t, "WHY CLOUDFLARE   8 / 8", "Simple DNS setup", "Registrar and DNS live in one dashboard. No nameserver juggling.", "#8")
    on = CARD
    p = ez(t, 0.9)
    c.card(140, 390, 1780, 800, p)
    cols = [(180, "TYPE"), (380, "NAME"), (580, "CONTENT"), (1500, "PROXY")]
    for x, s in cols:
        c.text(x, 420, s, F("m", 22, 500), DIM, p, on=on)
    c.line([(140, 466), (1780, 466)], LINE, 2, p, on)
    f = F("m", 28, 400)
    for i, (ty, name, content, prox) in enumerate(DNS):
        y = 508 + i * 78
        t0 = 1.6 + i * 1.3
        p = ez(t, t0, 0.3)
        if i:
            c.line([(180, y - 39), (1740, y - 39)], mix(LINE, 0.5, on), 2, p, on)
        c.pill(180, y - 22, ty, F("m", 24, 500), ORG, p, on, 14, 44)
        c.text(380, y, name, f, TXT, p, "lm", on)
        n = int(len(content) * clamp((t - t0 - 0.2) / 0.8))
        c.text(580, y, content[:n] + ("_" if 0 < n < len(content) else ""), f, TXT, p, "lm", on)
        q = ez(t, t0 + 1.0, 0.3)
        c.pill(1500, y - 22, "Proxied" if prox else "DNS only", F("m", 24, 500), ORG if prox else MUT, q, on, 14, 44)
    for i, s in enumerate(["On Cloudflare DNS from minute one", "Changes go live in seconds", "Mail records are added for you"]):
        p = ez(t, 7.0 + i * 0.45)
        x = [140, 760, 1250][i]
        c.check(x + 22, 868, 20, GRN, p)
        c.text(x + 58, 868, s, F("s", 30, 500), TXT, p, "lm")


RECAP = ["At-cost pricing, zero markup", "No surprise renewal fees", "Free WHOIS privacy", "Free email forwarding",
         "Global cache, unmetered bandwidth", "Smaller AWS bill for images", "Free SSL, DDoS protection, DNSSEC", "Simple DNS in one dashboard"]


def sc_recap(c, t):
    head(c, t, "RECAP", "Everything, ranked", "Eight reasons to register your domain at Cloudflare.")
    for i, s in enumerate(RECAP):
        col, row = i // 4, i % 4
        x, y = 140 + col * 830, 400 + row * 112
        p = ez(t, 0.9 + i * 0.4)
        c.card(x, y, x + 790, y + 92, p, r=18)
        c.text(x + 34, y + 46, "#%d" % (i + 1), F("g", 38, 700), ORG, p, "lm", CARD)
        c.text(x + 112, y + 46, s, F("s", 34, 500), TXT, p, "lm", CARD)
        c.check(x + 740, y + 46, 20, GRN, p, CARD)
    footnote(c, t, "Good to know: the domain must use Cloudflare's nameservers, and email is forwarding only, not hosted mailboxes.", 4.6)


def sc_outro(c, t):
    cx = W / 2
    c.text(cx, 130, "ONE STOP FOR BUYING YOUR DOMAIN NAME", F("m", 28, 500), ORG, ez(t, 0.1), "mm")
    p = ez(t, 0.2, 0.7)
    c.text(cx, 240 + (1 - p) * 24, "Found this useful?", F("g", 104, 700), TXT, p, "mm")

    p = ez(t, 1.0)
    yo = (1 - p) * 20
    c.card(240, 360 + yo, 930, 640 + yo, p)
    c.rect(300, 410 + yo, 700, 510 + yo, 50, RED, al=p, on=CARD)
    if p > 0.02:
        tri = [(346, 438 + yo), (346, 482 + yo), (384, 460 + yo)]
        c.d.polygon([(x * S, y * S) for x, y in tri], fill=mix((255, 255, 255), p, RED))
    c.text(410, 460 + yo, "SUBSCRIBE", F("g", 44, 700), (255, 255, 255), p, "lm", RED)
    c.text(300, 575 + yo, "Subscribe to our channel", F("s", 36, 500), TXT, p, "lm", CARD)

    p = ez(t, 1.7)
    yo = (1 - p) * 20
    c.card(990, 360 + yo, 1680, 640 + yo, p, outline=ORG)
    c.text(1050, 410 + yo, "VISIT", F("m", 26, 500), MUT, p, on=CARD)
    c.text(1050, 448 + yo, "hypebusted.com", F("g", 70, 700), ORG, p, on=CARD)
    c.text(1050, 575 + yo, "More honest reviews and comparisons", F("s", 31, 400), MUT, p, "lm", CARD)

    p = ez(t, 3.1)
    yo = (1 - p) * 20
    c.card(240, 700 + yo, 1680, 940 + yo, p)
    c.text(290, 736 + yo, "NOT SPONSORED. NOT AFFILIATED WITH CLOUDFLARE.", F("m", 26, 500), GRN, p, on=CARD)
    for i, line in enumerate(["Cloudflare sells domains at cost and makes no profit on them, so it has no",
                              "affiliate program. We earn nothing if you buy a domain there."]):
        c.text(290, 796 + yo + i * 50, line, F("s", 34, 400), TXT, p, on=CARD)


SCENES = [(sc_title, 5), (sc_trap, 9.5), (sc_tricks, 11.5), (sc_price, 9), (sc_renew, 10.5), (sc_privacy, 9),
          (sc_email, 9), (sc_cache, 8.5), (sc_aws, 10.5), (sc_security, 7.5), (sc_dns, 11), (sc_recap, 9.5), (sc_outro, 8)]
import narration
_dj = os.path.join(HERE, "audio", "durations.json")
if os.path.exists(_dj):
    import json
    # Scene length = lead-in + narration clip + tail. Never longer: extra seconds are audible dead air.
    # The scene's animation (timed for the base length in SCENES) is stretched or squeezed to fit.
    DURS = [narration.LEAD + n + narration.TAIL for n in json.load(open(_dj))]
else:
    DURS = [d for _, d in SCENES]
TOTAL = sum(DURS)
NFRAMES = round(TOTAL * FPS)
FADE = 0.35


def frame(n):
    T = n / FPS
    t, i = T, 0
    while i < len(SCENES) - 1 and t >= DURS[i]:
        t -= DURS[i]
        i += 1
    fn, base = SCENES[i]
    dur = DURS[i]
    c = Canvas()
    fn(c, t * base / dur)
    im = c.im.reduce(S)
    out = clamp((dur - t) / FADE)
    if out < 1:
        im = Image.blend(background().reduce(S), im, out)
    d = ImageDraw.Draw(im)
    d.rectangle((0, H - 6, W, H), fill=(26, 30, 39))
    d.rectangle((0, H - 6, round(W * T / TOTAL), H), fill=ORG)
    return im


def frame_bytes(n):
    return frame(n).tobytes()


def main():
    if sys.argv[1] == "preview":
        os.makedirs(os.path.join(HERE, "preview"), exist_ok=True)
        t0 = 0
        for i, ((fn, _), dur) in enumerate(zip(SCENES, DURS)):
            for tag, tt in (("mid", dur * 0.45), ("end", dur - FADE - 0.05)):
                if len(sys.argv) > 2 and tag not in sys.argv[2:]:
                    continue
                frame(round((t0 + tt) * FPS)).save(os.path.join(HERE, "preview", "%02d_%s_%s.png" % (i, fn.__name__, tag)))
            t0 += dur
        return
    import imageio_ffmpeg
    out = sys.argv[2]
    silent = os.path.join(HERE, "silent.mp4")
    wav = os.path.join(HERE, "audio", "track.wav")
    cmd = [imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "rgb24",
           "-s", "%dx%d" % (W, H), "-r", str(FPS), "-i", "-", "-c:v", "libx264", "-preset", "medium", "-crf", "17",
           "-pix_fmt", "yuv420p", "-movflags", "+faststart", silent]
    ff = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    with Pool(10) as pool:
        for k, b in enumerate(pool.imap(frame_bytes, range(NFRAMES), chunksize=4)):
            ff.stdin.write(b)
            if k % 300 == 0:
                print("frame %d/%d" % (k, NFRAMES), flush=True)
    ff.stdin.close()
    if ff.wait():
        sys.exit(1)
    narration.build_track(DURS, wav)
    sys.exit(subprocess.call([imageio_ffmpeg.get_ffmpeg_exe(), "-y", "-loglevel", "error", "-i", silent, "-i", wav,
                              "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", "-ar", "44100", "-shortest", "-movflags", "+faststart",
                              "-metadata", "title=One stop for buying your domain name", out]))


if __name__ == "__main__":
    main()
