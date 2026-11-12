"""Article infographic (1600x900): 5-year cost of one .com, promo registrar vs Cloudflare.

Usage: make_infographic.py OUT.png
All text >= 32 px on a 1600 px canvas (about 38 px on a 1920 frame) so it reads on a phone.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
W, H, S = 1600, 900, 2
BG, CARD, LINE = (12, 14, 19), (22, 26, 34), (52, 60, 75)
TXT, MUT = (242, 244, 247), (170, 180, 194)
ORG, RED, GRN, YEL = (246, 130, 31), (240, 82, 75), (61, 214, 140), (255, 214, 10)
_f = {}


def F(kind, size, weight=400):
    k = (kind, size, weight)
    if k not in _f:
        name = {"g": "space-grotesk.ttf", "s": "dm-sans.ttf", "m": "dm-mono-500.ttf"}[kind]
        f = ImageFont.truetype(os.path.join(HERE, "fonts", name), size * S)
        if kind != "m":
            f.set_variation_by_axes([weight])
        _f[k] = f
    return _f[k]


def mix(c, a, on=BG):
    return tuple(round(on[i] + (c[i] - on[i]) * a) for i in range(3))


def main(out):
    im = Image.new("RGB", (W * S, H * S), BG)
    glow = Image.new("L", (W // 8, H // 8), 0)
    ImageDraw.Draw(glow).ellipse((W // 8 - 90, -70, W // 8 + 40, 60), fill=60)
    glow = glow.filter(ImageFilter.GaussianBlur(26)).resize(im.size, Image.BICUBIC)
    im.paste(Image.new("RGB", im.size, ORG), (0, 0), glow)
    d = ImageDraw.Draw(im)

    def text(x, y, s, f, fill, anchor="la"):
        d.text((x * S, y * S), s, font=f, fill=fill, anchor=anchor)

    def rrect(box, r, fill=None, outline=None, w=3):
        d.rounded_rectangle([v * S for v in box], radius=r * S, fill=fill, outline=outline, width=w * S)

    # header
    text(80, 52, "BUYING A .COM DOMAIN?", F("m", 32), ORG)
    text(80, 100, "Compare the renewal, not year one", F("g", 76, 700), TXT)
    text(80, 200, "Five-year cost of one .com domain", F("s", 40, 500), MUT)

    cards = [
        (80, "Typical promo registrar", RED, ["$0.99", "$21.99 /yr", "Sometimes extra", "$88.95"], [GRN, RED, RED, RED]),
        (830, "Cloudflare Registrar", ORG, ["$11.17", "$11.17 /yr", "Free", "$55.85"], [TXT, GRN, GRN, GRN]),
    ]
    labels = ["Year 1", "Year 2 onward", "Privacy", "5-year total"]
    top, bottom, cw = 270, 740, 690
    for x, name, edge, vals, cols in cards:
        rrect((x, top, x + cw, bottom), 28, CARD, mix(edge, 0.9, CARD), 4 if edge == ORG else 3)
        text(x + 40, top + 34, name, F("g", 44, 700), TXT)
        for i, (lab, val, col) in enumerate(zip(labels, vals, cols)):
            y = top + 130 + i * 82
            last = i == 3
            if last:
                d.line([((x + 40) * S, (y - 14) * S), ((x + cw - 40) * S, (y - 14) * S)], fill=LINE, width=2 * S)
                y += 10
            text(x + 40, y + 20, lab, F("s", 38, 500), MUT, "lm")
            text(x + cw - 40, y + 20, val, F("g", 64 if last else 48, 700), col, "rm")
    # badge straddling the Cloudflare card's top edge
    bw = d.textlength("BEST VALUE", font=F("m", 32)) / S + 44
    bx = 830 + cw - bw - 36
    rrect((bx, top - 28, bx + bw, top + 28), 28, YEL)
    text(bx + bw / 2, top, "BEST VALUE", F("m", 32), (10, 10, 10), "mm")

    # savings strip
    msg = "Save $33.10 on one domain in five years"
    f = F("g", 52, 700)
    mw = d.textlength(msg, font=f) / S
    rrect((W / 2 - mw / 2 - 40, 772, W / 2 + mw / 2 + 40, 842), 35, mix(ORG, 0.16), ORG, 3)
    text(W / 2, 807, msg, f, TXT, "mm")
    text(W / 2, 872, "Promo-registrar prices are illustrative. Check renewal at checkout.", F("s", 32, 400), MUT, "mm")

    im.resize((W, H), Image.LANCZOS).save(out)
    print(out, os.path.getsize(out))


if __name__ == "__main__":
    main(sys.argv[1])
