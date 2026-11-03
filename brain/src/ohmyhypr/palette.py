"""Wallpaper color extraction and accessible desktop palette generation."""

from __future__ import annotations

import colorsys
import json
import math
import re
import subprocess
from collections import Counter
from pathlib import Path
from typing import Any

from . import paths


class PaletteError(RuntimeError):
    pass


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], amount: float) -> tuple[int, int, int]:
    return tuple(round(x * (1 - amount) + y * amount) for x, y in zip(a, b))


def _hex(rgb: tuple[int, int, int]) -> str:
    return "#" + "".join(f"{max(0, min(255, c)):02x}" for c in rgb)


def _luminance(rgb: tuple[int, int, int]) -> float:
    def linear(c: int) -> float:
        v = c / 255
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = map(linear, rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    x, y = sorted((_luminance(a), _luminance(b)))
    return (y + 0.05) / (x + 0.05)


def _readable(color: tuple[int, int, int], background: tuple[int, int, int], dark: bool) -> tuple[int, int, int]:
    target = (255, 255, 255) if dark else (0, 0, 0)
    if contrast(color, background) >= 4.5:
        return color
    low, high = 0.0, 1.0
    for _ in range(12):
        middle = (low + high) / 2
        if contrast(_mix(color, target, middle), background) >= 4.5:
            high = middle
        else:
            low = middle
    return _mix(color, target, high)


def _bar_opacity(histogram: Counter, background: tuple[int, int, int], foreground: tuple[int, int, int],
                 dark: bool) -> float:
    # Protect text against the brightest (or darkest for a light theme) 5% of
    # the wallpaper, while allowing dark wallpapers to retain transparency.
    ranked = sorted(histogram, key=_luminance, reverse=dark)
    threshold = max(1, math.ceil(sum(histogram.values()) * 0.05))
    count = 0
    behind = ranked[0]
    for color in ranked:
        count += histogram[color]
        behind = color
        if count >= threshold:
            break
    low, high = 0.38, 0.85
    if contrast(foreground, _mix(behind, background, low)) >= 4.5:
        return low
    for _ in range(12):
        middle = (low + high) / 2
        if contrast(foreground, _mix(behind, background, middle)) >= 4.5:
            high = middle
        else:
            low = middle
    return min(0.85, math.ceil(high * 100) / 100)


def from_pixels(data: bytes, dark: bool = True, opacity: float = 0.78) -> dict[str, Any]:
    if not data or len(data) % 3:
        raise PaletteError("image produced no valid RGB pixels")
    # Quantization keeps small antialiasing differences from dominating the histogram.
    histogram = Counter(tuple(min(255, (v // 16) * 16 + 8) for v in data[i:i + 3])
                        for i in range(0, len(data), 3))
    dominant = histogram.most_common(1)[0][0]
    candidates = []
    for rgb, count in histogram.items():
        hue, saturation, value = colorsys.rgb_to_hsv(*(v / 255 for v in rgb))
        if saturation >= 0.15 and value >= 0.12:
            candidates.append((math.sqrt(count) * saturation * (0.5 + value / 2), hue, rgb))
    candidates.sort(reverse=True)
    seed = candidates[0][2] if candidates else dominant
    hue = candidates[0][1] if candidates else 0.0
    alt = next((rgb for _, h, rgb in candidates if min(abs(h - hue), 1 - abs(h - hue)) >= 0.12), seed)
    bg = _mix(dominant, (0, 0, 0) if dark else (255, 255, 255), 0.87 if dark else 0.91)
    surface = _mix(bg, (255, 255, 255) if dark else (0, 0, 0), 0.09 if dark else 0.06)
    fg = _readable(_mix(bg, (255, 255, 255) if dark else (0, 0, 0), 0.9), surface, dark)
    muted = _readable(_mix(bg, fg, 0.62), surface, dark)
    accent = _readable(seed, surface, dark)
    accent_alt = _readable(alt, surface, dark)
    return {
        "bg": _hex(bg), "surface": _hex(surface), "fg": _hex(fg), "muted": _hex(muted),
        "accent": _hex(accent), "accent_alt": _hex(accent_alt),
        "urgent": _hex(_readable((225, 67, 76), surface, dark)),
        "border_active": _hex(accent), "border_inactive": _hex(_mix(bg, fg, 0.25)),
        "opacity": opacity, "bar_opacity": _bar_opacity(histogram, bg, fg, dark),
    }


def extract(image: Path, dark: bool = True, opacity: float = 0.78) -> dict[str, Any]:
    if not image.is_file():
        raise PaletteError(f"wallpaper not found: {image}")
    command = ["ffmpeg", "-v", "error", "-nostdin", "-i", str(image), "-frames:v", "1",
               "-vf", "scale=64:64,format=rgba", "-f", "rawvideo", "pipe:1"]
    try:
        proc = subprocess.run(command, capture_output=True, timeout=20, check=False)
    except FileNotFoundError as e:
        raise PaletteError("ffmpeg is required for wallpaper color extraction") from e
    except subprocess.TimeoutExpired as e:
        raise PaletteError("wallpaper color extraction timed out") from e
    if proc.returncode or len(proc.stdout) != 64 * 64 * 4:
        raise PaletteError("could not decode wallpaper as an image")
    # Transparent pixels are not visible on the desktop and should not bias the palette.
    pixels = b"".join(proc.stdout[i:i + 3] for i in range(0, len(proc.stdout), 4) if proc.stdout[i + 3] >= 128)
    return from_pixels(pixels, dark, opacity)


def current() -> dict[str, Any] | None:
    try:
        return json.loads(paths.PALETTE_JSON.read_text())
    except (OSError, json.JSONDecodeError):
        return None


def apply_file(path: Path) -> dict[str, Any]:
    """Apply a palette independently of the wallpaper and the theme's shape."""
    from . import theme

    try:
        raw = json.loads(path.read_text())
    except (OSError, ValueError) as e:
        raise PaletteError(f"cannot read palette: {e}") from e
    if isinstance(raw, dict) and "colors" in raw:
        raw = raw["colors"]
    keys = ("bg", "surface", "fg", "muted", "accent", "accent_alt", "urgent", "border_active", "border_inactive")
    if not isinstance(raw, dict) or any(
        not isinstance(raw.get(k), str) or not re.fullmatch(r"#[0-9a-fA-F]{6}", raw[k]) for k in keys
    ):
        raise PaletteError("palette must contain all color fields as #rrggbb values")
    with theme.state_lock():
        t = theme.current() or theme.resolve("sandrone")
        opacity = raw.get("opacity", t["palette"]["opacity"])
        if isinstance(opacity, bool) or not isinstance(opacity, (int, float)) or not 0 <= opacity <= 1:
            raise PaletteError("palette opacity must be between 0 and 1")
        t["palette"] = {**{key: raw[key] for key in keys}, "opacity": opacity}
        if "bar_opacity" in raw:
            bar_opacity = raw["bar_opacity"]
            if isinstance(bar_opacity, bool) or not isinstance(bar_opacity, (int, float)) or not 0 <= bar_opacity <= 1:
                raise PaletteError("palette bar_opacity must be between 0 and 1")
            t["palette"]["bar_opacity"] = bar_opacity
        t["palette_source"] = "file"
        return theme.publish(t)
