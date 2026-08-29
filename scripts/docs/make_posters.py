#!/usr/bin/env python3
"""Marketing poster generator for TalkToJesus.

Produces a set of print-quality PNG posters in ``deliverables/posters/`` that
match the visual identity of the shipped app: a soft luminous warm-amber halo
against a dusty lavender-mauve field, frosted-glass panels, serif display type
and a clean geometric sans for body copy.

Design notes
------------
*Palette* is sampled directly from the real app screenshots in ``docs/figures``
(see ``PALETTE`` below) and every background is synthesised in code as a stack
of elliptical "lights" blended over a vertical base ramp, finished with a
vignette and fine film grain -- the same grainy glow the app renders.

*Typography* substitutes the app's Lora / Poppins pairing with the closest
faces available on macOS: Georgia (transitional serif, near-identical colour
and x-height to Lora Bold) for display, Avenir Next for body copy, and
Kohinoor Telugu for Telugu.

*Telugu shaping.* Pillow on this machine is built without RAQM, so
``ImageDraw.text`` cannot reorder vowel signs or form the subscript conjuncts
Telugu needs (``డ్డ``, ``ట్ల`` ...) and produces visibly wrong output. All text
here is therefore shaped and rasterised by macOS CoreText through a small
``ctypes`` bridge (:func:`_render_mask`), which returns an 8-bit coverage mask
that Pillow then colourises and composites. That gives correct Telugu, proper
kerning for Latin, and keeps every layout/compositing operation in Pillow.

Usage
-----
    python3 scripts/docs/make_posters.py [--only 01,02] [--out DIR]
"""

from __future__ import annotations

import argparse
import ctypes
import math

from ctypes import (POINTER, byref, c_bool, c_double, c_long, c_size_t,
                    c_ubyte, c_uint32, c_void_p)
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

ROOT = Path(__file__).resolve().parents[2]
FIGURES = ROOT / "docs" / "figures"
OUT_DIR = ROOT / "deliverables" / "posters"

CREDIT = "A BITS Pilani capstone project by Manish Rachakonda"
APP_NAME = "TalkToJesus"

# --------------------------------------------------------------------------
# Palette -- sampled from docs/figures/fig-01-login.png and fig-03-home-english.png
# --------------------------------------------------------------------------

PALETTE = {
    "mauve_light": (205, 180, 189),   # top of the field, fig-01 @ (20,180)
    "mauve": (196, 170, 181),
    "mauve_deep": (162, 151, 185),    # bottom of the field, fig-01 @ (603,2450)
    "violet_deep": (140, 124, 160),
    "amber_soft": (253, 202, 140),    # halo edge,  fig-01 @ (603,300)
    "amber": (254, 179, 105),         # halo body,  fig-01 @ (603,560)
    "amber_hot": (253, 156, 69),      # halo core,  fig-03 @ (603,1500)
    "rose": (210, 142, 146),          # fig-01 @ (603,2000)
    "ink": (52, 32, 50),              # display type on light ground
    "ink_soft": (94, 66, 86),         # body copy on light ground
    "cream": (255, 246, 238),         # display type on dark ground
    "cream_soft": (231, 212, 220),
    "dusk_top": (74, 56, 88),
    "dusk_bottom": (34, 26, 48),
}

# Display / body / Telugu faces (PostScript names, resolved by CoreText).
SERIF = "Georgia-Bold"
SERIF_REG = "Georgia"
SERIF_IT = "Georgia-Italic"
SANS = "AvenirNext-Medium"
SANS_BOLD = "AvenirNext-DemiBold"
SANS_REG = "AvenirNext-Regular"
TELUGU = "KohinoorTelugu-Regular"
TELUGU_BOLD = "KohinoorTelugu-Semibold"
TELUGU_MED = "KohinoorTelugu-Medium"

# --------------------------------------------------------------------------
# CoreText bridge
# --------------------------------------------------------------------------

_CF = ctypes.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
_CT = ctypes.CDLL("/System/Library/Frameworks/CoreText.framework/CoreText")
_CG = ctypes.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")

CGFloat = c_double
_UTF8 = 0x08000100

_CF.CFStringCreateWithBytes.restype = c_void_p
_CF.CFStringCreateWithBytes.argtypes = [c_void_p, ctypes.c_char_p, c_long, c_uint32, c_bool]
_CF.CFNumberCreate.restype = c_void_p
_CF.CFNumberCreate.argtypes = [c_void_p, ctypes.c_int, c_void_p]
_CF.CFDictionaryCreate.restype = c_void_p
_CF.CFDictionaryCreate.argtypes = [c_void_p, POINTER(c_void_p), POINTER(c_void_p),
                                   c_long, c_void_p, c_void_p]
_CF.CFAttributedStringCreate.restype = c_void_p
_CF.CFAttributedStringCreate.argtypes = [c_void_p, c_void_p, c_void_p]
_CF.CFRelease.argtypes = [c_void_p]
_CF.CFStringGetCStringPtr.restype = ctypes.c_char_p
_CF.CFStringGetCStringPtr.argtypes = [c_void_p, c_uint32]
_CF.CFStringGetCString.argtypes = [c_void_p, ctypes.c_char_p, c_long, c_uint32]

_CT.CTFontCreateWithName.restype = c_void_p
_CT.CTFontCreateWithName.argtypes = [c_void_p, CGFloat, c_void_p]
_CT.CTFontCopyFullName.restype = c_void_p
_CT.CTFontCopyFullName.argtypes = [c_void_p]
_CT.CTLineCreateWithAttributedString.restype = c_void_p
_CT.CTLineCreateWithAttributedString.argtypes = [c_void_p]
_CT.CTLineGetTypographicBounds.restype = c_double
_CT.CTLineGetTypographicBounds.argtypes = [c_void_p, POINTER(CGFloat), POINTER(CGFloat),
                                           POINTER(CGFloat)]
_CT.CTLineDraw.argtypes = [c_void_p, c_void_p]

_CG.CGColorSpaceCreateDeviceRGB.restype = c_void_p
_CG.CGColorSpaceRelease.argtypes = [c_void_p]
_CG.CGBitmapContextCreate.restype = c_void_p
_CG.CGBitmapContextCreate.argtypes = [c_void_p, c_size_t, c_size_t, c_size_t, c_size_t,
                                      c_void_p, c_uint32]
_CG.CGContextRelease.argtypes = [c_void_p]
_CG.CGContextSetTextPosition.argtypes = [c_void_p, CGFloat, CGFloat]
_CG.CGContextSetShouldAntialias.argtypes = [c_void_p, c_bool]
_CG.CGContextSetShouldSmoothFonts.argtypes = [c_void_p, c_bool]
_CG.CGColorCreateGenericRGB.restype = c_void_p
_CG.CGColorCreateGenericRGB.argtypes = [CGFloat] * 4

_kFont = c_void_p.in_dll(_CT, "kCTFontAttributeName")
_kColor = c_void_p.in_dll(_CT, "kCTForegroundColorAttributeName")
_kKern = c_void_p.in_dll(_CT, "kCTKernAttributeName")
_kDictKeyCB = c_void_p.in_dll(_CF, "kCFTypeDictionaryKeyCallBacks")
_kDictValCB = c_void_p.in_dll(_CF, "kCFTypeDictionaryValueCallBacks")

_KCFNumberDoubleType = 13
_kCGImageAlphaPremultipliedLast = 1

_FONT_CACHE: dict[tuple[str, float], c_void_p] = {}
_WHITE = _CG.CGColorCreateGenericRGB(CGFloat(1), CGFloat(1), CGFloat(1), CGFloat(1))


def _cfstr(s: str) -> c_void_p:
    b = s.encode("utf-8")
    return _CF.CFStringCreateWithBytes(None, b, len(b), _UTF8, False)


def _cf_to_str(ref: c_void_p) -> str:
    p = _CF.CFStringGetCStringPtr(ref, _UTF8)
    if p:
        return p.decode()
    buf = ctypes.create_string_buffer(1024)
    _CF.CFStringGetCString(ref, buf, 1024, _UTF8)
    return buf.value.decode()


def _font(name: str, size: float) -> c_void_p:
    key = (name, round(size, 2))
    if key not in _FONT_CACHE:
        ref = _CT.CTFontCreateWithName(_cfstr(name), CGFloat(size), None)
        resolved = _cf_to_str(_CT.CTFontCopyFullName(ref))
        if resolved.lower().startswith("helvetica") and not name.lower().startswith("helvetica"):
            raise RuntimeError(f"font {name!r} is not installed (CoreText fell back to {resolved!r})")
        _FONT_CACHE[key] = ref
    return _FONT_CACHE[key]


def _make_line(text: str, font: str, size: float, tracking: float):
    """Build a shaped CTLine (white) and return (line, width, ascent, descent)."""
    fref = _font(font, size)
    keys = [_kFont, _kColor]
    vals = [fref, _WHITE]
    if tracking:
        d = c_double(tracking)
        keys.append(_kKern)
        vals.append(_CF.CFNumberCreate(None, _KCFNumberDoubleType, byref(d)))
    n = len(keys)
    ka = (c_void_p * n)(*keys)
    va = (c_void_p * n)(*vals)
    attrs = _CF.CFDictionaryCreate(None, ka, va, n, byref(_kDictKeyCB), byref(_kDictValCB))
    astr = _CF.CFAttributedStringCreate(None, _cfstr(text), attrs)
    line = _CT.CTLineCreateWithAttributedString(astr)
    asc, desc, lead = CGFloat(), CGFloat(), CGFloat()
    width = _CT.CTLineGetTypographicBounds(line, byref(asc), byref(desc), byref(lead))
    return line, float(width), float(asc.value), float(desc.value)


def measure(text: str, font: str, size: float, tracking: float = 0.0) -> tuple[float, float, float]:
    """Return (advance width, ascent, descent) for one shaped run."""
    _, w, a, d = _make_line(text, font, size, tracking)
    return w, a, d


def _render_mask(text: str, font: str, size: float, tracking: float = 0.0):
    """Rasterise one run through CoreText.

    Returns (mask, baseline, width) where *mask* is an 8-bit coverage image and
    *baseline* is the distance from the top of the mask to the text baseline.
    Rendering white into a premultiplied context makes the alpha channel an
    exact coverage mask, which Pillow then tints -- so glyph edges stay clean.
    """
    line, width, asc, desc = _make_line(text, font, size, tracking)
    pad = max(8, int(size * 0.45))
    W = max(1, int(math.ceil(width)) + pad * 2)
    H = max(1, int(math.ceil(asc + desc)) + pad * 2)
    cs = _CG.CGColorSpaceCreateDeviceRGB()
    buf = (c_ubyte * (W * H * 4))()
    ctx = _CG.CGBitmapContextCreate(buf, W, H, 8, W * 4, cs, _kCGImageAlphaPremultipliedLast)
    _CG.CGContextSetShouldAntialias(ctx, True)
    _CG.CGContextSetShouldSmoothFonts(ctx, False)
    baseline_from_bottom = pad + desc
    _CG.CGContextSetTextPosition(ctx, CGFloat(pad), CGFloat(baseline_from_bottom))
    _CT.CTLineDraw(line, ctx)
    rgba = Image.frombuffer("RGBA", (W, H), bytes(buf), "raw", "RGBA", 0, 1)
    mask = rgba.getchannel("A")
    _CG.CGContextRelease(ctx)
    _CG.CGColorSpaceRelease(cs)
    return mask, H - baseline_from_bottom, width, pad


def fit_size(text: str, font: str, max_w: float, start: float,
             minimum: float = 12.0, tracking: float = 0.0) -> float:
    """Largest size <= *start* whose advance width fits inside *max_w*."""
    size = start
    while size > minimum:
        w, _, _ = measure(text, font, size, tracking)
        if w <= max_w:
            return size
        size -= 1
    return minimum


# --------------------------------------------------------------------------
# Text placement
# --------------------------------------------------------------------------

Run = dict  # {"t": str, "f": font, "s": size, "c": rgb, "k": tracking}


def run(t, f, s, c, k=0.0) -> Run:
    return {"t": t, "f": f, "s": s, "c": c, "k": k}


def line_width(runs: list[Run]) -> float:
    return sum(measure(r["t"], r["f"], r["s"], r.get("k", 0.0))[0] for r in runs)


def put_line(canvas: Image.Image, runs: list[Run], x: float, baseline: float,
             anchor: str = "left", opacity: float = 1.0, shadow: dict | None = None):
    """Draw a row of runs sharing one baseline. Returns (left, right) x extent."""
    total = line_width(runs)
    if anchor == "center":
        x -= total / 2
    elif anchor == "right":
        x -= total
    start = x
    pen = x
    parts = []
    for r in runs:
        mask, base, w, pad = _render_mask(r["t"], r["f"], r["s"], r.get("k", 0.0))
        # the mask carries `pad` px of bleed on every side so overshooting
        # glyphs and Telugu vowel marks are not clipped -- back it out so the
        # first glyph's origin lands exactly on the pen position.
        parts.append((mask, base, r["c"], pen - pad))
        pen += w

    if shadow:
        sh = Image.new("L", canvas.size, 0)
        for mask, base, _c, px in parts:
            sh.paste(mask, (int(round(px)) + shadow.get("dx", 0),
                            int(round(baseline - base)) + shadow.get("dy", 0)), mask)
        sh = sh.filter(ImageFilter.GaussianBlur(shadow.get("blur", 12)))
        sh = sh.point(lambda v: int(v * shadow.get("alpha", 0.35)))
        layer = Image.new("RGBA", canvas.size, tuple(shadow.get("color", (0, 0, 0))) + (0,))
        layer.putalpha(sh)
        canvas.alpha_composite(layer)

    for mask, base, color, px in parts:
        if opacity < 1.0:
            mask = mask.point(lambda v: int(v * opacity))
        tint = Image.new("RGBA", mask.size, tuple(color) + (0,))
        tint.putalpha(mask)
        canvas.alpha_composite(tint, (int(round(px)), int(round(baseline - base))))
    return start, start + total


def wrap(text: str, font: str, size: float, max_w: float, tracking: float = 0.0) -> list[str]:
    words = text.split()
    lines, cur = [], ""
    for w in words:
        trial = f"{cur} {w}".strip()
        if measure(trial, font, size, tracking)[0] <= max_w or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def put_paragraph(canvas, text, font, size, color, x, baseline, max_w, leading,
                  anchor="left", tracking=0.0, opacity=1.0, shadow=None) -> float:
    """Draw wrapped copy. Returns the baseline of the line *after* the last one."""
    for ln in wrap(text, font, size, max_w, tracking):
        put_line(canvas, [run(ln, font, size, color, tracking)], x, baseline,
                 anchor=anchor, opacity=opacity, shadow=shadow)
        baseline += leading
    return baseline


# --------------------------------------------------------------------------
# Backgrounds
# --------------------------------------------------------------------------

def _smoothstep(a):
    return a * a * (3.0 - 2.0 * a)


def make_bg(W: int, H: int, top: tuple, bottom: tuple, lights: list[dict],
            vignette: float = 0.10, grain: float = 3.2, seed: int = 7) -> Image.Image:
    """Vertical base ramp + a stack of soft elliptical lights + vignette + grain."""
    yy = np.linspace(0.0, 1.0, H, dtype=np.float32)[:, None]
    t = _smoothstep(yy)
    img = (np.array(top, dtype=np.float32)[None, None, :] * (1 - t[..., None])
           + np.array(bottom, dtype=np.float32)[None, None, :] * t[..., None])
    img = np.repeat(img, W, axis=1)

    gx = np.arange(W, dtype=np.float32)[None, :]
    gy = np.arange(H, dtype=np.float32)[:, None]

    for L in lights:
        dx = (gx - L["cx"]) / L["rx"]
        dy = (gy - L["cy"]) / L["ry"]
        r = np.sqrt(dx * dx + dy * dy)
        a = np.clip(1.0 - r, 0.0, 1.0) ** L.get("power", 2.0)
        a = _smoothstep(a) * L.get("i", 1.0)
        col = np.array(L["c"], dtype=np.float32)[None, None, :]
        a3 = a[..., None]
        if L.get("mode") == "screen":
            img = 255.0 - (255.0 - img) * (255.0 - col * a3) / 255.0
        else:
            img = img * (1.0 - a3) + col * a3

    if vignette > 0:
        nx = (gx / W - 0.5) * 2.0
        ny = (gy / H - 0.5) * 2.0
        d = np.sqrt(nx * nx + ny * ny) / math.sqrt(2)
        v = 1.0 - vignette * _smoothstep(np.clip((d - 0.42) / 0.58, 0, 1))
        img *= v[..., None]

    if grain > 0:
        rng = np.random.default_rng(seed)
        n = rng.normal(0.0, grain, size=(H, W, 1)).astype(np.float32)
        img += n

    return Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def halo_lights(cx, cy, scale=1.0):
    """The app's haloed-figure glow: a head halo blooming into a body wash.

    Four nested elliptical lights with low falloff exponents, so the amber
    dissolves into the mauve field the way it does on the app's home screen
    rather than reading as a hard disc.
    """
    A = PALETTE
    return [
        dict(cx=cx, cy=cy + 760 * scale, rx=1180 * scale, ry=1080 * scale,
             c=A["rose"], i=0.40, power=2.6),
        dict(cx=cx, cy=cy + 400 * scale, rx=900 * scale, ry=900 * scale,
             c=A["amber_soft"], i=0.66, power=2.2),
        dict(cx=cx, cy=cy + 110 * scale, rx=540 * scale, ry=560 * scale,
             c=A["amber"], i=0.80, power=1.9),
        dict(cx=cx, cy=cy + 170 * scale, rx=290 * scale, ry=340 * scale,
             c=A["amber_hot"], i=0.72, power=1.8),
    ]


# --------------------------------------------------------------------------
# Rounded shapes, glass, device mockups
# --------------------------------------------------------------------------

SS = 4  # supersampling factor for vector shapes


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    w, h = size
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * SS - 1, h * SS - 1],
                                        radius=radius * SS, fill=255)
    return m.resize((w, h), Image.LANCZOS)


def rounded_ring(size: tuple[int, int], radius: int, width: float) -> Image.Image:
    w, h = size
    m = Image.new("L", (w * SS, h * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [width * SS / 2, width * SS / 2, w * SS - 1 - width * SS / 2, h * SS - 1 - width * SS / 2],
        radius=radius * SS, outline=255, width=max(1, int(width * SS)))
    return m.resize((w, h), Image.LANCZOS)


def drop_shadow(canvas: Image.Image, box, radius: int, blur: int = 40,
                alpha: float = 0.30, dy: int = 22, spread: int = 0,
                color=(46, 26, 44)):
    x0, y0, x1, y1 = box
    x0, y0, x1, y1 = x0 - spread, y0 - spread, x1 + spread, y1 + spread
    w, h = int(x1 - x0), int(y1 - y0)
    if w <= 0 or h <= 0:
        return
    m = rounded_mask((w, h), radius + spread)
    sh = Image.new("L", canvas.size, 0)
    sh.paste(m, (int(x0), int(y0) + dy))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    sh = sh.point(lambda v: int(v * alpha))
    layer = Image.new("RGBA", canvas.size, color + (0,))
    layer.putalpha(sh)
    canvas.alpha_composite(layer)


def glass_panel(canvas: Image.Image, box, radius: int, tint=(255, 255, 255),
                fill_alpha: int = 58, border_alpha: int = 96, blur: int = 22,
                shadow: bool = True):
    """Frosted-glass panel: blur what's behind, add a translucent fill + hairline."""
    x0, y0, x1, y1 = [int(v) for v in box]
    w, h = x1 - x0, y1 - y0
    if shadow:
        drop_shadow(canvas, (x0, y0, x1, y1), radius, blur=34, alpha=0.20, dy=14)
    mask = rounded_mask((w, h), radius)
    region = canvas.crop((x0, y0, x1, y1)).filter(ImageFilter.GaussianBlur(blur))
    frost = Image.new("RGBA", (w, h), tuple(tint) + (fill_alpha,))
    region = Image.alpha_composite(region, frost)
    region.putalpha(mask)
    canvas.alpha_composite(region, (x0, y0))
    ring = rounded_ring((w, h), radius, 2.0)
    ring = ring.point(lambda v: int(v * border_alpha / 255))
    edge = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    edge.putalpha(ring)
    canvas.alpha_composite(edge, (x0, y0))


_SHOT_CACHE: dict[str, Image.Image] = {}


def phone(shot: str, height: int, crop_top: int = 152, crop_bottom: int = 0,
          angle: float = 0.0) -> Image.Image:
    """Device mockup: screenshot in a dark rounded body with a light rim."""
    key = f"{shot}:{crop_top}:{crop_bottom}"
    if key not in _SHOT_CACHE:
        im = Image.open(FIGURES / shot).convert("RGB")
        im = im.crop((0, crop_top, im.width, im.height - crop_bottom))
        _SHOT_CACHE[key] = im
    src = _SHOT_CACHE[key]

    bezel = max(6, int(height * 0.0125))
    screen_h = height - bezel * 2
    screen_w = int(round(screen_h * src.width / src.height))
    W, H = screen_w + bezel * 2, height
    scr_radius = int(height * 0.043)
    body_radius = scr_radius + bezel

    body = Image.new("RGBA", (W, H), (24, 19, 30, 255))
    body.putalpha(rounded_mask((W, H), body_radius))

    screen = src.resize((screen_w, screen_h), Image.LANCZOS).convert("RGBA")
    screen.putalpha(rounded_mask((screen_w, screen_h), scr_radius))
    body.alpha_composite(screen, (bezel, bezel))

    rim = rounded_ring((W, H), body_radius, 2.4).point(lambda v: int(v * 0.42))
    rim_layer = Image.new("RGBA", (W, H), (255, 238, 226, 0))
    rim_layer.putalpha(rim)
    body.alpha_composite(rim_layer)

    if angle:
        body = body.rotate(angle, resample=Image.BICUBIC, expand=True)
    return body


def place_phone(canvas: Image.Image, dev: Image.Image, x: int, y: int,
                blur: int = 46, alpha: float = 0.36, dy: int = 26):
    sh = dev.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    full = Image.new("L", canvas.size, 0)
    full.paste(sh, (x, y + dy))
    full = full.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: int(v * alpha))
    layer = Image.new("RGBA", canvas.size, (40, 22, 42, 0))
    layer.putalpha(full)
    canvas.alpha_composite(layer)
    canvas.alpha_composite(dev, (x, y))


# --------------------------------------------------------------------------
# Small vector marks
# --------------------------------------------------------------------------

def cross_mark(size: int, color, thickness_ratio: float = 0.26) -> Image.Image:
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    t = s * thickness_ratio
    r = t * 0.42
    cx = s / 2
    d.rounded_rectangle([cx - t / 2, 0, cx + t / 2, s], radius=r, fill=tuple(color) + (255,))
    top = s * 0.30
    d.rounded_rectangle([0, top - t / 2, s, top + t / 2], radius=r, fill=tuple(color) + (255,))
    return img.resize((size, size), Image.LANCZOS)


def mic_mark(size: int, color) -> Image.Image:
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = tuple(color) + (255,)
    cw = s * 0.30
    d.rounded_rectangle([s / 2 - cw / 2, s * 0.10, s / 2 + cw / 2, s * 0.575],
                        radius=cw / 2, fill=col)
    lw = max(2, int(s * 0.062))
    d.arc([s * 0.235, s * 0.30, s * 0.765, s * 0.72], start=0, end=180, fill=col, width=lw)
    d.line([s / 2, s * 0.72, s / 2, s * 0.885], fill=col, width=lw)
    d.line([s * 0.31, s * 0.885, s * 0.69, s * 0.885], fill=col, width=lw)
    return img.resize((size, size), Image.LANCZOS)


def wordmark(canvas: Image.Image, x: float, baseline: float, size: float,
             color, anchor: str = "left", opacity: float = 1.0):
    """Cross glyph + the TalkToJesus wordmark, set on one baseline."""
    tracking = size * 0.012
    w_text = measure(APP_NAME, SERIF, size, tracking)[0]
    mark = int(size * 0.90)
    gap = size * 0.34
    total = mark + gap + w_text
    if anchor == "center":
        x -= total / 2
    elif anchor == "right":
        x -= total
    cm = cross_mark(mark, color)
    if opacity < 1.0:
        cm.putalpha(cm.getchannel("A").point(lambda v: int(v * opacity)))
    canvas.alpha_composite(cm, (int(x), int(baseline - mark * 0.90)))
    put_line(canvas, [run(APP_NAME, SERIF, size, color, tracking)],
             x + mark + gap, baseline, opacity=opacity)
    return total


def credit(canvas: Image.Image, x: float, baseline: float, color,
           size: float = 21, anchor: str = "left", opacity: float = 0.9):
    put_line(canvas, [run(CREDIT, SANS, size, color, size * 0.055)],
             x, baseline, anchor=anchor, opacity=opacity)


def rule(canvas: Image.Image, x0, y, x1, color, alpha=70, weight=2):
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rectangle([x0, y, x1, y + weight - 1],
                                    fill=tuple(color) + (alpha,))
    canvas.alpha_composite(layer)


def pill(canvas, cx, baseline, label_runs, pad_x=44, pad_y=22, radius=None,
         fill_alpha=64, border_alpha=110, tint=(255, 255, 255), blur=18,
         icon=None, icon_gap=18, shadow=False, anchor='center'):
    """Frosted capsule holding a row of runs, anchored on cx."""
    tw = line_width(label_runs)
    asc = max(measure(r["t"], r["f"], r["s"], r.get("k", 0))[1] for r in label_runs)
    desc = max(measure(r["t"], r["f"], r["s"], r.get("k", 0))[2] for r in label_runs)
    icon_w = (icon.size[0] + icon_gap) if icon is not None else 0
    W = int(tw + icon_w + pad_x * 2)
    H = int(asc + desc + pad_y * 2)
    x0 = int(cx if anchor == 'left' else (cx - W if anchor == 'right' else cx - W / 2))
    y0 = int(baseline - asc - pad_y)
    r = radius if radius is not None else H // 2
    glass_panel(canvas, (x0, y0, x0 + W, y0 + H), r, tint=tint,
                fill_alpha=fill_alpha, border_alpha=border_alpha, blur=blur, shadow=shadow)
    tx = x0 + pad_x
    if icon is not None:
        canvas.alpha_composite(icon, (int(tx), int(baseline - asc + (asc - icon.size[1]) / 2)))
        tx += icon.size[0] + icon_gap
    put_line(canvas, label_runs, tx, baseline)
    return (x0, y0, x0 + W, y0 + H)


# ==========================================================================
# Posters
# ==========================================================================

P = PALETTE


def poster_01_speak():
    """1080x1080 -- the core promise: one button, a spoken answer."""
    W = H = 1080
    canvas = make_bg(W, H, P["mauve_light"], P["mauve_deep"],
                     halo_lights(540, 300, scale=0.80), vignette=0.13, seed=11)

    wordmark(canvas, W / 2, 138, 38, P["ink"], anchor="center", opacity=0.92)

    put_line(canvas, [run("A VOICE-FIRST SPIRITUAL COMPANION", SANS_BOLD, 22,
                          P["ink_soft"], 4.6)], W / 2, 302, anchor="center", opacity=0.88)

    s = fit_size("He listens.", SERIF, 720, 150, tracking=-2)
    put_line(canvas, [run("Speak.", SERIF, s, P["ink"], -2)], W / 2, 452, anchor="center")
    put_line(canvas, [run("He listens.", SERIF, s, P["ink"], -2)], W / 2, 452 + s * 1.06,
             anchor="center")

    put_paragraph(canvas, "Ask aloud in English or Telugu. Hear a spoken reply "
                          "that cites scripture and closes in prayer.",
                  SANS, 30, P["ink_soft"], W / 2, 706, 690, 46, anchor="center")

    pill(canvas, W / 2, 878, [run("Talk to Jesus", SANS_BOLD, 34, P["ink"], 0.4)],
         pad_x=46, pad_y=26, icon=mic_mark(40, P["ink"]), icon_gap=20,
         fill_alpha=76, border_alpha=120, shadow=True)

    credit(canvas, W / 2, 1008, P["ink_soft"], 21, anchor="center", opacity=0.8)
    return "01-speak-he-listens-1080x1080.png", canvas


def poster_02_telugu():
    """1080x1080 -- the bilingual differentiator, led in Telugu."""
    W = H = 1080
    M = 84
    col = 420          # text measure; Telugu vowel marks overhang the advance
    canvas = make_bg(W, H, P["mauve_light"], P["mauve_deep"],
                     halo_lights(830, 290, scale=0.78), vignette=0.14, seed=23)

    dev = phone("fig-05-home-telugu.png", 836)
    place_phone(canvas, dev, W - 66 - dev.size[0], 124)

    wordmark(canvas, M, 136, 34, P["ink"], opacity=0.92)

    pill(canvas, M, 244,
         [run("EN", SANS_BOLD, 24, P["ink"], 1.6),
          run("   |   ", SANS, 24, P["ink_soft"], 0),
          run("\u0c24\u0c46", TELUGU_MED, 24, P["ink"], 0)],
         pad_x=26, pad_y=14, fill_alpha=78, border_alpha=120, anchor="left")

    ts = fit_size("\u0c2e\u0c3e\u0c1f\u0c4d\u0c32\u0c3e\u0c21\u0c02\u0c21\u0c3f",
                  TELUGU_BOLD, col, 88)
    put_line(canvas, [run("\u0c2f\u0c47\u0c38\u0c41\u0c24\u0c4b", TELUGU_BOLD, ts, P["ink"])],
             M, 400)
    put_line(canvas, [run("\u0c2e\u0c3e\u0c1f\u0c4d\u0c32\u0c3e\u0c21\u0c02\u0c21\u0c3f",
                          TELUGU_BOLD, ts, P["ink"])], M, 400 + ts * 1.36)

    put_line(canvas, [run("Talk to Jesus \u2014 out loud, in Telugu.", SANS_BOLD, 26,
                          P["ink"], 0.2)], M, 606)

    put_paragraph(canvas, "Ask in your own language. He answers in Telugu \u2014 "
                          "with scripture, and a prayer.",
                  SANS, 24, P["ink_soft"], M, 664, 452, 38)

    card = (M, 750, M + 442, 926)
    glass_panel(canvas, card, 30, fill_alpha=78, border_alpha=118, blur=20)
    put_line(canvas, [run("\u0c28\u0c3e \u0c2c\u0c3f\u0c21\u0c4d\u0c21", TELUGU_BOLD, 54,
                          P["ink"])], M + 34, 834)
    put_line(canvas, [run("\u201cmy child\u201d \u2014 how every answer begins.", SANS, 20,
                          P["ink_soft"], 0.2)], M + 34, 894)

    credit(canvas, M, 1010, P["ink_soft"], 21, opacity=0.8)
    return "02-telugu-naa-bidda-1080x1080.png", canvas


def poster_03_features():
    """1080x1350 -- feature showcase built from three real device screens."""
    W, H = 1080, 1350
    canvas = make_bg(W, H, P["mauve_light"], P["mauve_deep"],
                     halo_lights(540, 210, scale=0.86), vignette=0.15, seed=41)

    wordmark(canvas, W / 2, 140, 36, P["ink"], anchor="center", opacity=0.92)

    s = fit_size("Voice. Scripture. Song.", SERIF, 830, 96, tracking=-1.4)
    put_line(canvas, [run("Voice. Scripture. Song.", SERIF, s, P["ink"], -1.4)],
             W / 2, 306, anchor="center")

    put_paragraph(canvas, "One companion for the whole devotional day \u2014 a voice that "
                          "answers, a bilingual Bible, and twelve hymns to rest in.",
                  SANS, 26, P["ink_soft"], W / 2, 372, 780, 41, anchor="center")

    chips = ["Voice conversations", "6 Bible translations", "12 bundled hymns"]
    widths = [line_width([run(c, SANS_BOLD, 22, P["ink"], 0.6)]) + 56 for c in chips]
    gap = 20
    x = W / 2 - (sum(widths) + gap * (len(chips) - 1)) / 2
    for c, cw in zip(chips, widths):
        pill(canvas, x, 508, [run(c, SANS_BOLD, 22, P["ink"], 0.6)],
             pad_x=28, pad_y=16, fill_alpha=74, border_alpha=116, anchor="left")
        x += cw + gap

    left = phone("fig-09-bible-telugu.png", 528, angle=7)
    right = phone("fig-13-songs-library.png", 528, crop_bottom=70, angle=-7)
    mid = phone("fig-03-home-english.png", 604)

    place_phone(canvas, left, int(252 - left.size[0] / 2), 636, blur=38, alpha=0.28)
    place_phone(canvas, right, int(828 - right.size[0] / 2), 636, blur=38, alpha=0.28)
    place_phone(canvas, mid, int(W / 2 - mid.size[0] / 2), 596, blur=50, alpha=0.36)

    credit(canvas, W / 2, 1290, P["ink_soft"], 22, anchor="center", opacity=0.82)
    return "03-features-1080x1350.png", canvas


def poster_04_two_am():
    """1920x1080 -- availability and comfort, in a dusk-toned variant."""
    W, H = 1920, 1080
    M = 148
    col = 760
    lights = [
        dict(cx=1452, cy=430, rx=980, ry=940, c=(196, 120, 96), i=0.50, power=2.4),
        dict(cx=1452, cy=430, rx=540, ry=540, c=(238, 156, 92), i=0.52, power=2.0),
        dict(cx=1452, cy=470, rx=280, ry=310, c=(253, 176, 96), i=0.40, power=1.8),
        dict(cx=170, cy=1010, rx=980, ry=760, c=(98, 76, 126), i=0.45, power=2.4),
        dict(cx=90, cy=60, rx=700, ry=560, c=(92, 72, 118), i=0.30, power=2.4),
    ]
    canvas = make_bg(W, H, P["dusk_top"], P["dusk_bottom"], lights,
                     vignette=0.30, grain=3.0, seed=57)

    dev = phone("fig-06-voice-recording.png", 932)
    place_phone(canvas, dev, int(1452 - dev.size[0] / 2), 74, blur=62, alpha=0.46, dy=30)

    wordmark(canvas, M, 172, 38, P["cream"], opacity=0.95)

    put_line(canvas, [run("WHEN THE HOUSE IS QUIET", SANS_BOLD, 22, P["cream_soft"], 5.0)],
             M, 330, opacity=0.85)

    hs = fit_size("when there\u2019s no one", SERIF, col, 100, tracking=-1.6)
    for i, ln in enumerate(["At 2 a.m.,", "when there\u2019s no one", "to ask."]):
        put_line(canvas, [run(ln, SERIF, hs, P["cream"], -1.6)], M, 432 + i * hs * 1.10)

    rule(canvas, M, 704, M + 120, P["amber"], alpha=175, weight=3)

    put_paragraph(canvas, "TalkToJesus listens and answers out loud \u2014 in English or "
                          "Telugu \u2014 with scripture, and a prayer to close.",
                  SANS, 27, P["cream_soft"], M, 768, col, 44)

    pill(canvas, M, 892,
         [run("3 conversations free", SANS_BOLD, 22, P["cream"], 0.8),
          run("   \u00b7   ", SANS, 22, P["amber"], 0),
          run("then \u20b9499 / month", SANS_BOLD, 22, P["cream"], 0.8)],
         pad_x=30, pad_y=17, fill_alpha=30, border_alpha=64, blur=14, anchor="left")

    credit(canvas, M, 984, P["cream_soft"], 21, opacity=0.68)
    return "04-two-am-1920x1080.png", canvas


def poster_05_how_it_works():
    """1920x1080 -- the three-step voice loop, for a talk slide or LinkedIn."""
    W, H = 1920, 1080
    M = 132
    lights = halo_lights(1372, 180, scale=0.95)
    lights.append(dict(cx=120, cy=1080, rx=1000, ry=760, c=P["rose"],
                       i=0.22, power=2.6))
    canvas = make_bg(W, H, P["mauve_light"], P["mauve_deep"], lights,
                     vignette=0.14, seed=73)

    dev = phone("fig-03-home-english.png", 900)
    place_phone(canvas, dev, W - 190 - dev.size[0], 92, blur=54, alpha=0.34)

    wordmark(canvas, M, 168, 38, P["ink"], opacity=0.92)

    put_line(canvas, [run("HOW IT WORKS", SANS_BOLD, 22, P["ink_soft"], 5.0)],
             M, 312, opacity=0.85)

    hs = fit_size("One button. One voice.", SERIF, 720, 88, tracking=-1.4)
    put_line(canvas, [run("One button.", SERIF, hs, P["ink"], -1.4)], M, 404)
    put_line(canvas, [run("One voice that answers.", SERIF, hs, P["ink"], -1.4)],
             M, 404 + hs * 1.10)

    steps = [
        ("01", "Press and speak", "In English or in Telugu \u2014 whichever you pray in."),
        ("02", "He answers aloud", "A first-person pastoral voice, grounded in scripture."),
        ("03", "Ends in prayer", "Every reply closes with a short prayer over you."),
    ]
    top, row_h = 596, 116
    for i, (num, title, body) in enumerate(steps):
        y = top + i * row_h
        put_line(canvas, [run(num, SERIF, 40, P["amber_hot"], 0)], M, y)
        put_line(canvas, [run(title, SANS_BOLD, 28, P["ink"], 0.3)], M + 84, y - 12)
        put_line(canvas, [run(body, SANS, 22, P["ink_soft"], 0.2)], M + 84, y + 26)
        if i < len(steps) - 1:
            rule(canvas, M, y + 56, M + 840, P["ink_soft"], alpha=44, weight=1)

    credit(canvas, M, 964, P["ink_soft"], 21, opacity=0.78)
    return "05-how-it-works-1920x1080.png", canvas


POSTERS = {
    "01": poster_01_speak,
    "02": poster_02_telugu,
    "03": poster_03_features,
    "04": poster_04_two_am,
    "05": poster_05_how_it_works,
}


def main():
    ap = argparse.ArgumentParser(description="Generate the TalkToJesus marketing posters.")
    ap.add_argument("--out", default=str(OUT_DIR))
    ap.add_argument("--only", default="", help="comma separated poster ids, e.g. 01,03")
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    wanted = [k.strip() for k in args.only.split(",") if k.strip()] or list(POSTERS)

    for key in wanted:
        name, img = POSTERS[key]()
        path = out / name
        img.convert("RGB").save(path, "PNG", optimize=True)
        print(f"{path}  {img.width}x{img.height}")


if __name__ == "__main__":
    main()
