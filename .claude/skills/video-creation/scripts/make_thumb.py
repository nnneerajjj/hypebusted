"""Compose the YouTube thumbnail (1280x720) from a generated portrait.

Usage: make_thumb.py PORTRAIT.png OUT.png
"""
import os
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from rembg import remove

HERE = os.path.dirname(os.path.abspath(__file__))
W, H = 2560, 1440  # 2x, downscaled at the end
BG = (12, 14, 19)
ORG = (246, 130, 31)
RED = (240, 60, 55)
YEL = (255, 214, 10)
CROP = (450, 30, 960, 535)  # head and shoulders from red_dress_woman.png, above the gift box
WHITE = (255, 255, 255)


def font(size, weight=700):
    f = ImageFont.truetype(os.path.join(HERE, "fonts", "space-grotesk.ttf"), size)
    f.set_variation_by_axes([weight])
    return f


def fit(s, maxw, size):
    while font(size).getlength(s) > maxw:
        size -= 4
    return font(size)


def glow(center, radius, color, strength):
    m = Image.new("L", (W // 8, H // 8), 0)
    cx, cy, r = center[0] // 8, center[1] // 8, radius // 8
    ImageDraw.Draw(m).ellipse((cx - r, cy - r, cx + r, cy + r), fill=strength)
    m = m.filter(ImageFilter.GaussianBlur(r * 0.45)).resize((W, H), Image.BICUBIC)
    return Image.new("RGB", (W, H), color), m


def main(src, out):
    im = Image.new("RGB", (W, H), BG)
    col, m = glow((1880, 720), 1100, ORG, 210)
    im.paste(col, (0, 0), m)
    col, m = glow((300, 1500), 700, RED, 90)
    im.paste(col, (0, 0), m)

    # person cutout, white outline + soft shadow
    # Crop above the gift box (sits at the bottom of the source photo), then remove the green backdrop.
    photo = Image.open(src).convert("RGB").crop(CROP)
    person = remove(photo)
    ph = 1300
    person = person.resize((round(person.width * ph / person.height), ph), Image.LANCZOS)
    r, g, b, alpha = person.split()
    alpha = alpha.filter(ImageFilter.MinFilter(3))  # trim the 1px green fringe
    # de-spill: along the edge band, green can't exceed red (hair, skin and dress are all red-dominant)
    band = ImageChops.subtract(alpha.filter(ImageFilter.MaxFilter(15)), alpha.filter(ImageFilter.MinFilter(15)))
    g = Image.composite(ImageChops.darker(g, r), g, band.point(lambda v: 255 if v else 0))
    person = Image.merge("RGBA", (r, g, b, alpha))
    px, py = 2000 - person.width // 2, H - ph
    pad = 60
    big = Image.new("L", (person.width + pad * 2, person.height + pad * 2), 0)
    big.paste(alpha, (pad, pad))
    outline = big.filter(ImageFilter.MaxFilter(17)).filter(ImageFilter.GaussianBlur(2))
    shadow = big.filter(ImageFilter.GaussianBlur(40))
    im.paste(Image.new("RGB", big.size, (0, 0, 0)), (px - pad - 30, py - pad + 20), shadow)
    im.paste(Image.new("RGB", big.size, WHITE), (px - pad, py - pad), outline)
    im.paste(person, (px, py), alpha)

    d = ImageDraw.Draw(im)
    x, maxw = 96, 1330
    lines = [("STOP", YEL), ("OVERPAYING", WHITE), ("FOR DOMAINS", WHITE)]
    y = 70
    for s, c in lines:
        f = fit(s, maxw, 330 if s == "STOP" else 250)
        d.text((x + 10, y + 12), s, font=f, fill=(0, 0, 0), stroke_width=16, stroke_fill=(0, 0, 0))
        d.text((x, y), s, font=f, fill=c, stroke_width=14, stroke_fill=(0, 0, 0))
        y += f.size * 0.98 + 26

    # price row: struck-out renewal price -> at-cost price badge
    y0 = 1090
    f1 = font(190)
    old = "$21.99"
    d.text((x, y0), old, font=f1, fill=RED, stroke_width=12, stroke_fill=(0, 0, 0))
    wold = f1.getlength(old)
    d.line((x - 14, y0 + 190, x + wold + 14, y0 + 10), fill=WHITE, width=22)
    ax = x + wold + 60
    d.line((ax, y0 + 118, ax + 130, y0 + 118), fill=WHITE, width=24)
    d.polygon([(ax + 110, y0 + 56), (ax + 200, y0 + 118), (ax + 110, y0 + 180)], fill=WHITE)
    bx = ax + 250
    f2 = font(200)
    new = "$11.17"
    wnew = f2.getlength(new)
    d.rounded_rectangle((bx + 10, y0 - 8 + 12, bx + wnew + 110, y0 + 252), radius=46, fill=(0, 0, 0))
    d.rounded_rectangle((bx, y0 - 8, bx + wnew + 100, y0 + 240), radius=46, fill=YEL)
    d.text((bx + 50, y0 - 6), new, font=f2, fill=(10, 10, 10))

    im = im.resize((1280, 720), Image.LANCZOS)
    im.save(out, quality=95)
    print(out, os.path.getsize(out))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
