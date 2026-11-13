#!/usr/bin/env python3
# =============================================================================
#  Zorza OS – generator grafik.
#  Wszystkie tapety i obrazy są tworzone proceduralnie (gradienty, kształty,
#  szum fraktalny) – bez żadnych zewnętrznych zdjęć ani grafik.
#
#  Użycie: render-assets.py <katalog-projektu> <katalog-wyjściowy> [--preview]
#    --preview  renderuje w niskiej rozdzielczości (szybki podgląd)
#
#  Wynik:
#    <out>/chroot/...   pliki kopiowane do systemu (tapety, Plymouth, SDDM…)
#    <out>/grub/...     motyw GRUB (tło, czcionki)
# =============================================================================
import hashlib
import json
import math
import os
import shutil
import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = Path(sys.argv[1]).resolve()
OUT = Path(sys.argv[2]).resolve()
PREVIEW = "--preview" in sys.argv

PAL = json.loads((SRC / "branding/palette.json").read_text())
W, H = (960, 540) if PREVIEW else (3840, 2160)
RNG_SEED = 2026


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255.0


C = {k: hexrgb(v) for k, v in PAL.items() if isinstance(v, str) and v.startswith("#")}


# ----------------------------------------------------------------------------- helpers
def grid(w, h):
    y, x = np.mgrid[0:h, 0:w].astype(np.float32)
    return x / w, y / h


def lerp(a, b, t):
    return a + (b - a) * t


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def vgradient(h, w, stops):
    """Pionowy gradient: stops = [(pozycja 0..1, kolor rgb), ...]."""
    ys = np.linspace(0, 1, h, dtype=np.float32)
    out = np.zeros((h, 3), np.float32)
    pos = [s[0] for s in stops]
    for c in range(3):
        out[:, c] = np.interp(ys, pos, [s[1][c] for s in stops])
    return np.repeat(out[:, None, :], w, axis=1)


def fbm(h, w, rng, octaves=5, base=4, aspect=(1, 1), persistence=0.55):
    """Szum fraktalny (value noise) skalowany interpolacją bikubiczną."""
    acc = np.zeros((h, w), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        gh = max(2, int(base * (2 ** o) * aspect[0]))
        gw = max(2, int(base * (2 ** o) * aspect[1]))
        small = (rng.random((gh, gw)) * 255).astype(np.uint8)
        big = np.asarray(Image.fromarray(small).resize((w, h), Image.BICUBIC), np.float32) / 255.0
        acc += big * amp
        tot += amp
        amp *= persistence
    return acc / tot


def ridge1d(w, rng, octaves=6, base=3, persistence=0.5):
    """Jednowymiarowy profil (grzbiety gór / wydm)."""
    xs = np.linspace(0, 1, w, dtype=np.float32)
    acc = np.zeros(w, np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = base * (2 ** o) + 1
        pts = rng.random(n).astype(np.float32)
        acc += np.interp(xs, np.linspace(0, 1, n), pts) * amp
        tot += amp
        amp *= persistence
    acc /= tot
    # wygładzenie
    k = max(3, w // 300)
    acc = np.convolve(np.pad(acc, k, mode="edge"), np.ones(k) / k, mode="same")[k:-k]
    return acc


def glow(x, y, cx, cy, r, aspect=W / H):
    d2 = ((x - cx) * aspect) ** 2 + (y - cy) ** 2
    return np.exp(-d2 / (r * r))


def add(img, color, alpha):
    return img + color[None, None, :] * alpha[..., None]


def over(img, color, alpha):
    a = np.clip(alpha, 0, 1)[..., None]
    return img * (1 - a) + color[None, None, :] * a


def stars(img, rng, count, ymax=1.0, bright=1.0):
    h, w, _ = img.shape
    n = int(count * (w * h) / (3840 * 2160))
    xs = rng.integers(0, w, n)
    ys = (rng.random(n) ** 1.6 * ymax * h).astype(int)
    br = rng.random(n) ** 3 * bright
    layer = np.zeros((h, w), np.float32)
    layer[ys.clip(0, h - 1), xs] = br
    big = rng.random(n) > 0.985
    for x0, y0, b in zip(xs[big], ys[big], br[big]):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            yy, xx = y0 + dy, x0 + dx
            if 0 <= yy < h and 0 <= xx < w:
                layer[yy, xx] = max(layer[yy, xx], b * 0.5)
    rad = 0.6 if PREVIEW else 1.1
    layer = np.asarray(Image.fromarray((layer * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(rad)), np.float32) / 255 * 2.2
    return img + np.array([0.92, 0.94, 1.0])[None, None, :] * layer[..., None]


def finish(img, rng, grain=0.012):
    """Ziarno + dithering, aby gradienty nie miały pasm."""
    h, w, _ = img.shape
    img = img + (rng.random((h, w, 1), dtype=np.float32) - 0.5) * grain
    img = img + (rng.random((h, w, 3), dtype=np.float32) - 0.5) / 255.0
    return Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")


def blur_arr(a, r):
    if a.ndim == 2:
        im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8))
        return np.asarray(im.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255
    im = Image.fromarray(np.clip(a * 255, 0, 255).astype(np.uint8), "RGB")
    return np.asarray(im.filter(ImageFilter.GaussianBlur(r)), np.float32) / 255


def silhouette(h, w, profile, base_y, height):
    """Maska: 1 poniżej linii profilu."""
    ys = np.linspace(0, 1, h, dtype=np.float32)[:, None]
    line = base_y - profile[None, :] * height
    aa = 1.5 / h
    return smoothstep(line - aa, line + aa, ys)


# ----------------------------------------------------------------------------- wallpapers
def wp_zorza(seed):
    """Zorza – kurtyny zorzy polarnej nad nocnym horyzontem z odbiciem w jeziorze."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, C["night"] * 0.6), (0.55, C["deep"]), (0.72, C["dusk"]), (1, C["night"] * 0.7)])
    img = stars(img, rng, 9000, ymax=0.7)
    # kurtyny: linia bazowa falująca + pionowe smugi
    for i, (col, cy, amp, th, inten) in enumerate([
        (C["teal"], 0.46, 0.08, 0.10, 0.9),
        (C["violet"], 0.38, 0.10, 0.14, 0.85),
        (C["pink"], 0.30, 0.07, 0.10, 0.5),
    ]):
        ph = rng.random() * 6.28
        base = cy + amp * np.sin(x * 5.0 + ph) + 0.035 * np.sin(x * 13.0 + ph * 2)
        streak = fbm(H, W, rng, octaves=4, base=6, aspect=(0.08, 6))
        d = (y - base)
        curtain = np.where(d < 0, np.exp(-(d / (th * 2.2)) ** 2), np.exp(-(d / (th * 0.18)) ** 2))
        curtain *= 0.35 + 1.1 * streak ** 2
        img = add(img, col, curtain * inten)
    # poświata nad horyzontem
    img = add(img, C["violet"], glow(x, y, 0.5, 0.66, 0.35) * 0.25)
    horizon = 0.66
    # góry w oddali
    for k, (by, hh, shade) in enumerate([(0.66, 0.10, 0.55), (0.665, 0.06, 0.35)]):
        prof = ridge1d(W, rng, base=3 + k * 2)
        m = silhouette(H, W, prof, by, hh) * (y < horizon + 0.002)
        img = over(img, C["night"] * shade + C["dusk"] * 0.15 * (1 - k), m)
    # jezioro: odbicie nieba z falkami
    sky = img.copy()
    hy = int(horizon * H)
    below = H - hy
    src_rows = np.clip(2 * hy - np.arange(hy, H), 0, H - 1)
    ripple = (np.sin(np.arange(below)[:, None] * (0.9 if not PREVIEW else 0.25) + x[hy:] * 40) * 3).astype(int)
    cols = np.clip(np.arange(W)[None, :] + ripple, 0, W - 1)
    refl = sky[src_rows[:, None], cols]
    fade = np.linspace(0.75, 0.25, below, dtype=np.float32)[:, None, None]
    img[hy:] = refl * fade + C["night"][None, None, :] * (1 - fade) * 0.6
    img = add(img, C["mist"], np.exp(-((y - horizon) / 0.004) ** 2) * 0.07)
    vign = 1 - 0.35 * (((x - 0.5) * 1.4) ** 2 + ((y - 0.5) * 1.2) ** 2)
    return finish(img * vign[..., None], rng)


def wp_swit(seed):
    """Świt – warstwy wzgórz i wschodzące słońce."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, C["deep"]), (0.3, C["violet"] * 0.75 + C["deep"] * 0.25),
                           (0.5, C["pink"] * 0.9), (0.62, C["gold"]), (1, C["gold"])])
    sx, sy = 0.62, 0.56
    img = add(img, C["gold"], glow(x, y, sx, sy, 0.22) * 0.6)
    sun = ((x - sx) * W / H) ** 2 + (y - sy) ** 2 < 0.055 ** 2
    img = np.clip(img, 0, 1)
    img = over(img, np.array([1, 0.96, 0.88], np.float32), blur_arr(sun.astype(np.float32), 1.2))
    img = add(img, np.array([1, 0.9, 0.75], np.float32), glow(x, y, sx, sy, 0.07) * 0.25)
    stars_layer = stars(np.zeros_like(img), rng, 1500, ymax=0.25, bright=0.5)
    img = img + stars_layer * (1 - y[..., None] * 3).clip(0, 1)
    layers = [(0.60, 0.12, 0.15), (0.68, 0.14, 0.35), (0.77, 0.16, 0.55), (0.88, 0.18, 0.78), (0.98, 0.16, 0.95)]
    for i, (by, hh, depth) in enumerate(layers):
        prof = ridge1d(W, rng, base=2 + i, persistence=0.45)
        m = silhouette(H, W, prof, by, hh)
        col = lerp(lerp(C["pink"], C["violet"], 0.6), C["night"], depth)
        haze = np.exp(-((y - (by - hh * 0.5)) / 0.12) ** 2) * (1 - depth) * 0.25
        img = over(img, col, m)
        img = add(img, C["gold"], m * haze)
    return finish(img, rng)


def wp_fale(seed):
    """Fale – miękkie, nakładające się wstęgi koloru."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, C["night"]), (1, C["deep"])])
    img = add(img, C["violet"], glow(x, y, 0.2, 0.2, 0.5) * 0.35)
    cols = [C["teal"], C["violet"], lerp(C["violet"], C["pink"], 0.5), C["pink"], C["gold"], lerp(C["pink"], C["night"], 0.5)]
    n = len(cols)
    for i, col in enumerate(cols):
        by = 0.25 + i * 0.12
        a1, f1, p1 = 0.06 + 0.03 * rng.random(), 2 + 2 * rng.random(), rng.random() * 6.28
        a2, f2, p2 = 0.02, 5 + 3 * rng.random(), rng.random() * 6.28
        line = by + a1 * np.sin(x * f1 * math.pi + p1) + a2 * np.sin(x * f2 * math.pi + p2)
        d = y - line
        m = smoothstep(-1.5 / H, 1.5 / H, d)
        shade = 0.55 + 0.45 * np.exp(-np.clip(d, 0, None) / 0.08)
        layer_col = lerp(col, C["night"], 0.25 + 0.5 * (i / n))
        img = img * (1 - 0.35 * np.exp(-((d + 0.004) / 0.02) ** 2) * (d < 0))[..., None]  # cień nad krawędzią
        img = over(img, np.zeros(3, np.float32), np.zeros_like(m))
        img = img * (1 - m[..., None]) + (layer_col[None, None, :] * shade[..., None]) * m[..., None]
        img = add(img, C["mist"], np.exp(-(d / 0.0018) ** 2) * 0.25 * (1 - i / n))
    return finish(img, rng)


def wp_krysztal(seed):
    """Kryształ – kompozycja low-poly w barwach zorzy."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    base = vgradient(H, W, [(0, C["deep"]), (0.5, C["violet"] * 0.55 + C["deep"] * 0.45), (1, C["night"])])
    base = add(base, C["pink"], glow(x, y, 0.8, 0.3, 0.45) * 0.55)
    base = add(base, C["teal"], glow(x, y, 0.15, 0.85, 0.4) * 0.45)
    base = np.clip(base, 0, 1)
    im = Image.new("RGB", (W, H))
    dr = ImageDraw.Draw(im)
    nx, ny = 26, 15
    cw, ch = W / nx, H / ny
    pts = {}
    for j in range(ny + 1):
        for i in range(nx + 1):
            jx = 0 if i in (0, nx) else (rng.random() - 0.5) * cw * 0.5
            jy = 0 if j in (0, ny) else (rng.random() - 0.5) * ch * 0.5
            pts[(i, j)] = (i * cw + jx, j * ch + jy)
    light = np.array([-0.4, -0.6, 0.7]); light /= np.linalg.norm(light)
    for j in range(ny):
        for i in range(nx):
            a, b, c_, d = pts[(i, j)], pts[(i + 1, j)], pts[(i + 1, j + 1)], pts[(i, j + 1)]
            tris = [(a, b, c_), (a, c_, d)] if (i + j) % 2 else [(a, b, d), (b, c_, d)]
            for t in tris:
                cx = sum(p[0] for p in t) / 3; cy = sum(p[1] for p in t) / 3
                colr = base[int(min(H - 1, cy)), int(min(W - 1, cx))]
                hgt = [rng.random() * 0.25 for _ in t]
                v1 = np.array([t[1][0] - t[0][0], t[1][1] - t[0][1], (hgt[1] - hgt[0]) * cw])
                v2 = np.array([t[2][0] - t[0][0], t[2][1] - t[0][1], (hgt[2] - hgt[0]) * cw])
                nrm = np.cross(v1, v2); nrm /= (np.linalg.norm(nrm) + 1e-6)
                if nrm[2] < 0: nrm = -nrm
                sh = 0.75 + 0.45 * float(np.dot(nrm, light))
                col = tuple(int(np.clip(v * sh, 0, 1) * 255) for v in colr)
                dr.polygon(t, fill=col)
    arr = np.asarray(im, np.float32) / 255
    arr = add(arr, C["mist"], glow(x, y, 0.55, 0.45, 0.18) * 0.12)
    return finish(arr, rng, grain=0.008)


def wp_glebia(seed):
    """Głębia – mgławica i gwiazdy."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, C["night"] * 0.5), (1, C["night"] * 0.8)])
    n1 = fbm(H, W, rng, octaves=7, base=3)
    n2 = fbm(H, W, rng, octaves=6, base=4)
    band = np.exp(-((y - 0.5 - 0.25 * (x - 0.5) - 0.08 * np.sin(x * 6)) / 0.22) ** 2)
    neb = np.clip((n1 - 0.38) * 2.2, 0, 1) ** 1.6 * band
    img = add(img, C["violet"], neb * 0.9)
    img = add(img, C["pink"], np.clip((n2 - 0.5) * 3, 0, 1) ** 2 * band * 0.7)
    img = add(img, C["teal"], np.clip((n1 * n2 - 0.25) * 4, 0, 1) ** 2 * band * 0.5)
    dust = np.clip((fbm(H, W, rng, octaves=6, base=8) - 0.5) * 3, 0, 1)
    img = img * (1 - 0.6 * dust * band)[..., None]
    img = stars(img, rng, 16000, ymax=1.0)
    img = add(img, np.array([1, 0.9, 0.95], np.float32), glow(x, y, 0.58, 0.48, 0.035) * 0.9)
    img = add(img, C["pink"], glow(x, y, 0.58, 0.48, 0.12) * 0.25)
    return finish(img, rng)


def wp_wydmy(seed):
    """Wydmy – jasna, pastelowa tapeta do motywu jasnego."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, np.array([0.86, 0.87, 0.98], np.float32)), (0.45, C["mist"]),
                           (0.6, np.array([1.0, 0.89, 0.86], np.float32)), (1, np.array([0.99, 0.83, 0.78], np.float32))])
    img = add(img, C["gold"], glow(x, y, 0.3, 0.42, 0.18) * 0.18)
    sun = ((x - 0.3) * W / H) ** 2 + (y - 0.40) ** 2 < 0.045 ** 2
    img = over(img, np.array([1, 0.97, 0.93], np.float32), sun * 0.9)
    tints = [np.array(c, np.float32) for c in [(0.93, 0.80, 0.86), (0.96, 0.76, 0.74), (0.90, 0.70, 0.78), (0.82, 0.64, 0.80), (0.70, 0.58, 0.82)]]
    for i, col in enumerate(tints):
        by = 0.55 + i * 0.1
        prof = ridge1d(W, rng, octaves=3, base=1 + i % 2, persistence=0.35)
        line = by - prof * 0.12
        d = y - line[None, :]
        m = smoothstep(-1.5 / H, 1.5 / H, d)
        light = 1.04 - 0.18 * np.clip(d / 0.12, 0, 1) + 0.1 * np.exp(-(d / 0.01) ** 2)
        side = 1 + 0.06 * np.sin(x * 9 + i)  # łagodne zbocza
        img = img * (1 - m[..., None]) + (col[None, None, :] * (light * side)[..., None]) * m[..., None]
    return finish(img, rng, grain=0.01)


def wp_mgla(seed):
    """Mgła – minimalistyczny, jasny gradient siatkowy (domyślna jasna)."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = np.ones((H, W, 3), np.float32) * C["mist"]
    blobs = [(0.18, 0.25, 0.42, C["violet"], 0.35), (0.82, 0.2, 0.38, C["pink"], 0.3),
             (0.65, 0.85, 0.45, C["gold"], 0.28), (0.2, 0.9, 0.35, C["teal"], 0.25), (0.5, 0.5, 0.3, C["mist"], 0.6)]
    for bx, by, r, col, a in blobs:
        img = over(img, col, glow(x, y, bx, by, r) * a)
    warp = fbm(H, W, rng, octaves=3, base=2)
    img = img * (0.97 + 0.06 * warp)[..., None]
    return finish(img, rng, grain=0.01)


def wp_zmierzch(seed):
    """Zmierzch – ostatnie światło nad pasmem gór i mgłą w dolinach."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    img = vgradient(H, W, [(0, C["night"]), (0.35, C["dusk"]), (0.55, C["violet"] * 0.8 + C["pink"] * 0.2),
                           (0.66, C["pink"]), (0.72, C["gold"] * 0.9 + C["pink"] * 0.1), (1, C["night"])])
    img = stars(img, rng, 5000, ymax=0.35)
    img = add(img, C["gold"], glow(x, y, 0.3, 0.7, 0.25) * 0.45)
    # wąski sierp księżyca
    mx, my, mr = 0.78, 0.18, 0.03
    d1 = ((x - mx) * W / H) ** 2 + (y - my) ** 2
    d2 = ((x - mx - 0.008) * W / H) ** 2 + (y - my + 0.006) ** 2
    moon = (d1 < mr ** 2) & (d2 > (mr * 0.92) ** 2)
    img = over(img, np.array([1, 0.95, 0.88], np.float32), blur_arr(moon.astype(np.float32), 1.2))
    img = add(img, C["pink"], glow(x, y, mx, my, 0.06) * 0.15)
    for i, (by, hh, depth) in enumerate([(0.72, 0.22, 0.3), (0.8, 0.2, 0.55), (0.9, 0.18, 0.8), (1.0, 0.15, 0.95)]):
        prof = ridge1d(W, rng, octaves=7, base=3 + i, persistence=0.55) ** 1.3
        m = silhouette(H, W, prof, by, hh)
        col = lerp(C["violet"] * 0.6, C["night"] * 0.6, depth)
        img = over(img, col, m)
        mist = np.exp(-((y - by + 0.02) / 0.03) ** 2) * (1 - depth) * 0.35
        img = add(img, C["pink"], mist * (0.5 + 0.5 * fbm(H, W, rng, octaves=3, base=3, aspect=(1, 3))))
    return finish(img, rng)


def wp_horyzont(phase, seed=77):
    """Horyzont – tapeta dynamiczna (ta sama kompozycja w 4 porach dnia)."""
    rng = np.random.default_rng(seed)
    x, y = grid(W, H)
    P = {
        "swit": dict(sky=[(0, C["dusk"]), (0.45, C["pink"]), (0.62, C["gold"])], sun=(0.25, 0.6), glowc=C["gold"],
                     hills=C["violet"] * 0.45, st=0.3, water=0.7),
        "dzien": dict(sky=[(0, np.array([0.30, 0.45, 0.95], np.float32)), (0.45, np.array([0.58, 0.72, 1.0], np.float32)),
                           (0.62, np.array([0.93, 0.92, 1.0], np.float32))], sun=(0.62, 0.18), glowc=np.array([1, 1, 0.92], np.float32),
                      hills=np.array([0.36, 0.40, 0.70], np.float32), st=0.0, water=0.85),
        "zmierzch": dict(sky=[(0, C["deep"]), (0.4, C["violet"]), (0.55, C["pink"]), (0.62, C["gold"])], sun=(0.75, 0.6),
                         glowc=C["pink"], hills=C["night"] * 0.9 + C["violet"] * 0.1, st=0.4, water=0.6),
        "noc": dict(sky=[(0, C["night"] * 0.5), (0.45, C["deep"]), (0.62, C["dusk"])], sun=None, glowc=C["violet"],
                    hills=C["night"] * 0.7, st=1.0, water=0.5),
    }[phase]
    horizon = 0.62
    img = vgradient(H, W, P["sky"] + [(1, P["sky"][-1][1])])
    if P["st"]:
        s = stars(np.zeros_like(img), np.random.default_rng(seed + 1), 9000, ymax=0.6)
        img = img + s * P["st"]
    if phase == "noc":
        streak = fbm(H, W, rng, octaves=4, base=6, aspect=(0.08, 6))
        base = 0.35 + 0.06 * np.sin(x * 4 + 1)
        d = y - base
        cur = np.where(d < 0, np.exp(-(d / 0.25) ** 2), np.exp(-(d / 0.02) ** 2)) * (0.3 + streak ** 2)
        img = add(img, C["teal"], cur * 0.55)
        img = add(img, C["violet"], cur * np.exp(-((y - 0.25) / 0.2) ** 2) * 0.4)
        mx, my = 0.8, 0.15
        moon = ((x - mx) * W / H) ** 2 + (y - my) ** 2 < 0.025 ** 2
        img = over(img, np.array([0.95, 0.95, 1.0], np.float32), blur_arr(moon.astype(np.float32), 1.0))
        img = add(img, C["mist"], glow(x, y, mx, my, 0.07) * 0.12)
    if P["sun"]:
        sx, sy = P["sun"]
        img = add(img, P["glowc"], glow(x, y, sx, sy, 0.25) * 0.5)
        sun = ((x - sx) * W / H) ** 2 + (y - sy) ** 2 < 0.04 ** 2
        img = over(img, np.array([1, 0.96, 0.88], np.float32), blur_arr(sun.astype(np.float32), 1.0))
    else:
        img = add(img, P["glowc"], glow(x, y, 0.5, horizon, 0.3) * 0.25)
    rr = np.random.default_rng(seed + 5)
    for i, (hh, mul) in enumerate([(0.14, 0.75), (0.08, 1.0)]):
        prof = ridge1d(W, rr, base=2 + 2 * i)
        m = silhouette(H, W, prof, horizon, hh) * (y <= horizon)
        img = over(img, P["hills"] * mul, m)
    hy = int(horizon * H)
    src = np.clip(2 * hy - np.arange(hy, H), 0, H - 1)
    ripple = (np.sin(np.arange(H - hy)[:, None] * (0.8 if not PREVIEW else 0.2) + x[hy:] * 30) * 3).astype(int)
    cols = np.clip(np.arange(W)[None, :] + ripple, 0, W - 1)
    refl = img[src[:, None], cols]
    f = np.linspace(P["water"], P["water"] * 0.4, H - hy, dtype=np.float32)[:, None, None]
    img[hy:] = refl * f + P["hills"][None, None, :] * 0.3 * (1 - f)
    img = add(img, C["mist"], np.exp(-((y - horizon) / 0.004) ** 2) * 0.08)
    return finish(img, rng)


WALLPAPERS = [
    # (katalog, nazwa wyświetlana, funkcja, ciemna?)
    ("Zorza", "Zorza", lambda: wp_zorza(11), True),
    ("Swit", "Świt", lambda: wp_swit(12), True),
    ("Fale", "Fale", lambda: wp_fale(13), True),
    ("Krysztal", "Kryształ", lambda: wp_krysztal(14), True),
    ("Glebia", "Głębia", lambda: wp_glebia(15), True),
    ("Zmierzch", "Zmierzch", lambda: wp_zmierzch(16), True),
    ("Wydmy", "Wydmy", lambda: wp_wydmy(17), False),
    ("Mgla", "Mgła", lambda: wp_mgla(18), False),
]
HORYZONT_PHASES = ["swit", "dzien", "zmierzch", "noc"]


# ----------------------------------------------------------------------------- output helpers
def save(img, path, quality=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.suffix == ".jpg":
        img.save(path, quality=quality or 93, subsampling=0, optimize=True)
    else:
        img.save(path, optimize=True)


def wallpaper_package(dirname, display, img, dark_img=None):
    root = OUT / "chroot/usr/share/wallpapers" / dirname
    res = f"{W}x{H}"
    save(img, root / f"contents/images/{res}.png")
    if dark_img is not None:
        save(dark_img, root / f"contents/images_dark/{res}.png")
    shot = img.copy(); shot.thumbnail((400, 250))
    save(shot, root / "contents/screenshot.png")
    meta = {
        "KPlugin": {
            "Authors": [{"Name": "Zorza OS"}],
            "Id": dirname,
            "License": "CC-BY-SA-4.0",
            "Name": display,
            "Name[pl]": display,
        }
    }
    (root / "metadata.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))


def rsvg(svg, png, w, h=None):
    png.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["rsvg-convert", "-w", str(w)] + (["-h", str(h)] if h else []) + ["-o", str(png), str(svg)]
    subprocess.run(cmd, check=True)


def compose_logo(bg, logo_png, size, center, alpha=1.0):
    lg = Image.open(logo_png).convert("RGBA").resize((size, size), Image.LANCZOS)
    if alpha < 1:
        a = lg.split()[3].point(lambda v: int(v * alpha)); lg.putalpha(a)
    bg = bg.convert("RGBA")
    bg.alpha_composite(lg, (int(center[0] - size / 2), int(center[1] - size / 2)))
    return bg


# ----------------------------------------------------------------------------- main
def stamp_of():
    h = hashlib.sha256()
    for p in [Path(__file__), SRC / "branding/palette.json", *sorted((SRC / "branding/logo").glob("*.svg"))]:
        h.update(p.read_bytes())
    h.update(b"preview" if PREVIEW else b"full")
    return h.hexdigest()


def main():
    stamp = OUT / ".stamp"
    sig = stamp_of()
    if stamp.exists() and stamp.read_text() == sig:
        print("[assets] aktualne – pomijam renderowanie")
        return
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir(parents=True)
    tmp = OUT / "_tmp"; tmp.mkdir()

    # --- logo
    logo_dir = OUT / "chroot/usr/share/zorza/branding"
    logo_dir.mkdir(parents=True, exist_ok=True)
    for svg in (SRC / "branding/logo").glob("*.svg"):
        shutil.copy(svg, logo_dir / svg.name)
    mark = tmp / "mark-512.png"
    rsvg(SRC / "branding/logo/zorza-mark.svg", mark, 512)
    for s in (16, 22, 24, 32, 48, 64, 128, 256, 512):
        rsvg(SRC / "branding/logo/zorza-mark.svg", OUT / f"chroot/usr/share/icons/hicolor/{s}x{s}/apps/zorza.png", s)
        shutil.copy(OUT / f"chroot/usr/share/icons/hicolor/{s}x{s}/apps/zorza.png",
                    OUT / f"chroot/usr/share/icons/hicolor/{s}x{s}/apps/zorza-logo.png")
    scal = OUT / "chroot/usr/share/icons/hicolor/scalable/apps"; scal.mkdir(parents=True, exist_ok=True)
    shutil.copy(SRC / "branding/logo/zorza-mark.svg", scal / "zorza.svg")
    shutil.copy(SRC / "branding/logo/zorza-mark.svg", scal / "zorza-logo.svg")
    shutil.copy(SRC / "branding/logo/zorza-symbolic.svg", scal / "start-here-zorza-symbolic.svg")
    shutil.copy(SRC / "branding/logo/zorza-mark.svg", scal / "start-here-zorza.svg")
    rsvg(SRC / "branding/logo/zorza-wordmark.svg", logo_dir / "zorza-wordmark.png", 700)
    shutil.copy(SRC / "branding/ascii/zorza.txt", logo_dir / "zorza-ascii.txt")
    shutil.copy(mark, logo_dir / "zorza-logo.png")

    # --- tapety
    rendered = {}
    for dirname, display, fn, dark in WALLPAPERS:
        print(f"[assets] tapeta {display}…", flush=True)
        img = fn()
        rendered[dirname] = img
        wallpaper_package(dirname, display, img)
    print("[assets] tapeta dynamiczna Horyzont…", flush=True)
    phases = {p: wp_horyzont(p) for p in HORYZONT_PHASES}
    # pakiet "Horyzont": jasny = dzień, ciemny = noc (Plasma przełącza z motywem),
    # a zorza-dynamic-wallpaper podmienia 4 pory dnia wg zegara.
    wallpaper_package("Horyzont", "Horyzont (dzień/noc)", phases["dzien"], phases["noc"])
    for p, img in phases.items():
        save(img, OUT / f"chroot/usr/share/wallpapers/Horyzont/phases/{p}.png")

    # --- GRUB: tło 1920x1080 + czcionki
    grub = OUT / "grub/zorza"
    grub.mkdir(parents=True, exist_ok=True)
    gb = rendered["Zorza"].resize((1920, 1080), Image.LANCZOS)
    gb = Image.fromarray((np.asarray(gb, np.float32) * 0.62).astype(np.uint8))
    gb = compose_logo(gb, mark, 150, (960, 230))
    gb.convert("RGB").save(grub / "background.png", optimize=True)
    # zaznaczenie pozycji menu (styl 9-slice: *_c.png)
    sel = Image.new("RGBA", (8, 44), tuple(int(v * 255) for v in C["violet"]) + (210,))
    sel.save(grub / "select_c.png")
    for side in ("w", "e"):
        Image.new("RGBA", (6, 44), tuple(int(v * 255) for v in C["violet"]) + (210,)).save(grub / f"select_{side}.png")
    fonts = {
        "inter_regular_16": ("/usr/share/fonts/opentype/inter/Inter-Regular.otf", 16),
        "inter_regular_20": ("/usr/share/fonts/opentype/inter/Inter-Regular.otf", 20),
        "inter_bold_24": ("/usr/share/fonts/opentype/inter/Inter-Bold.otf", 24),
    }
    for name, (ttf, size) in fonts.items():
        if not Path(ttf).exists():
            alt = list(Path("/usr/share/fonts").rglob(Path(ttf).name))
            ttf = str(alt[0]) if alt else ttf
        if shutil.which("grub-mkfont") and Path(ttf).exists():
            subprocess.run(["grub-mkfont", "-s", str(size), "-o", str(grub / f"{name}.pf2"), ttf], check=True, stderr=subprocess.DEVNULL)
        else:
            print(f"[assets] UWAGA: brak grub-mkfont lub czcionki {ttf}")

    # --- Plymouth
    ply = OUT / "chroot/usr/share/plymouth/themes/zorza"
    ply.mkdir(parents=True, exist_ok=True)
    pb = rendered["Zorza"].resize((1920, 1080), Image.LANCZOS)
    pb = Image.fromarray((np.asarray(pb, np.float32) * 0.45).astype(np.uint8))
    pb.save(ply / "background.png", optimize=True)
    rsvg(SRC / "branding/logo/zorza-mark.svg", ply / "logo.png", 180)
    rsvg(SRC / "branding/logo/zorza-wordmark.svg", ply / "wordmark.png", 360)
    # kropka postępu i poświata
    for name, col, r in (("dot.png", C["mist"], 7), ("dot-accent.png", C["pink"], 7)):
        d = Image.new("RGBA", (r * 4, r * 4), (0, 0, 0, 0))
        dd = ImageDraw.Draw(d)
        dd.ellipse((r, r, r * 3, r * 3), fill=tuple(int(v * 255) for v in col) + (255,))
        d = d.filter(ImageFilter.GaussianBlur(0.8))
        d.save(ply / name)
    gl = np.zeros((360, 360, 4), np.uint8)
    yy, xx = np.mgrid[0:360, 0:360]
    g = np.exp(-(((xx - 180) ** 2 + (yy - 180) ** 2) / (110 ** 2)))
    gl[..., :3] = (C["violet"] * 255).astype(np.uint8)
    gl[..., 3] = (g * 160).astype(np.uint8)
    Image.fromarray(gl, "RGBA").save(ply / "glow.png")
    # pole hasła (szyfrowanie dysku)
    entry = Image.new("RGBA", (320, 44), (0, 0, 0, 0))
    ImageDraw.Draw(entry).rounded_rectangle((0, 0, 319, 43), 14, fill=(20, 26, 60, 230), outline=tuple(int(v * 255) for v in C["violet"]) + (255,), width=2)
    entry.save(ply / "entry.png")
    bullet = Image.new("RGBA", (14, 14), (0, 0, 0, 0))
    ImageDraw.Draw(bullet).ellipse((1, 1, 12, 12), fill=(244, 245, 251, 255))
    bullet.save(ply / "bullet.png")

    # --- SDDM tło
    sd = OUT / "chroot/usr/share/sddm/themes/zorza"
    sd.mkdir(parents=True, exist_ok=True)
    rendered["Zorza"].resize((2560, 1440), Image.LANCZOS).save(sd / "background.jpg", quality=92)
    shutil.copy(mark, sd / "logo.png")

    # --- Calamares
    cal = OUT / "chroot/etc/calamares/branding/zorza"
    cal.mkdir(parents=True, exist_ok=True)
    shutil.copy(mark, cal / "logo.png")
    rsvg(SRC / "branding/logo/zorza-mark.svg", cal / "icon.png", 128)
    rsvg(SRC / "branding/logo/zorza-wordmark.svg", cal / "wordmark.png", 520)
    slide_bgs = ["Zorza", "Fale", "Glebia", "Swit", "Krysztal", "Zmierzch"]
    for i, name in enumerate(slide_bgs, 1):
        sb = rendered[name].resize((800, 450), Image.LANCZOS)
        sb = Image.fromarray((np.asarray(sb, np.float32) * 0.55).astype(np.uint8))
        sb.save(cal / f"slide{i}.jpg", quality=90)

    # --- Podglądy globalnego motywu i miniatury
    for variant, wp in (("dark", "Zorza"), ("light", "Mgla")):
        pv = rendered[wp].resize((800, 450), Image.LANCZOS).convert("RGBA")
        d = ImageDraw.Draw(pv, "RGBA")
        panel = (22, 26, 52, 200) if variant == "dark" else (250, 250, 255, 210)
        fg = (230, 232, 245, 255) if variant == "dark" else (40, 44, 70, 255)
        d.rectangle((0, 0, 800, 18), fill=panel)
        d.rounded_rectangle((230, 404, 570, 440), 12, fill=panel)
        for i in range(7):
            cx = 262 + i * 46
            d.rounded_rectangle((cx - 14, 408, cx + 14, 436), 8, fill=tuple(int(v * 255) for v in hexrgb(list(PAL["accents"].values())[i % 6])) + (255,))
        d.rounded_rectangle((180, 70, 620, 350), 14, fill=panel)
        d.rounded_rectangle((180, 70, 620, 100), 14, fill=tuple(int(v * 255) for v in C["violet"]) + (230,))
        d.text((200, 120), "Zorza OS", fill=fg)
        out = OUT / f"chroot/usr/share/plasma/look-and-feel/org.zorza.{variant}/contents/previews"
        out.mkdir(parents=True, exist_ok=True)
        pv.convert("RGB").save(out / "preview.png")
        pv.convert("RGB").resize((400, 225), Image.LANCZOS).save(out / "fullscreenpreview.jpg", quality=90)
        pv.convert("RGB").save(OUT / f"chroot/usr/share/zorza/branding/theme-{variant}.png")

    # Miniatury tapet dla aplikacji Welcome / System Center
    th = OUT / "chroot/usr/share/zorza/thumbs"
    th.mkdir(parents=True, exist_ok=True)
    for name, img in list(rendered.items()) + [("Horyzont", phases["dzien"])]:
        t = img.resize((384, 216), Image.LANCZOS)
        t.save(th / f"{name}.jpg", quality=88)

    shutil.rmtree(tmp)
    stamp.write_text(sig)
    print("[assets] gotowe")


if __name__ == "__main__":
    main()
