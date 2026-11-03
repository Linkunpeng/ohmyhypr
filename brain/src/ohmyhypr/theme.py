"""Themes: one file switches wallpaper, palette, shapes, fonts and effects.

themes/<id>/theme.toml (repo) or ~/.config/ohmyhypr/themes/<id>/theme.toml (user)
  → `omh theme apply <id>` resolves it over DEFAULTS and writes
     $XDG_STATE_HOME/ohmyhypr/theme.json   read live by Quickshell
     $XDG_STATE_HOME/ohmyhypr/theme.lua    read by hypr/lua/omh/settings.lua
  → reloads Hyprland (only inside an ohmyhypr session) and runs [hooks].
"""

from __future__ import annotations

import copy
import fcntl
import json
import os
import re
import subprocess
import time
import tempfile
from contextlib import contextmanager
import tomllib
from pathlib import Path
from typing import Any

from . import palette, paths

DEFAULTS: dict[str, Any] = {
    "meta": {"name": "", "description": "", "dark": True},
    "wallpaper": {"path": "", "fit": "cover"},
    "palette": {
        "bg": "#181926",
        "surface": "#24273a",
        "fg": "#cad3f5",
        "muted": "#6e738d",
        "accent": "#8aadf4",
        "accent_alt": "#c6a0f6",
        "urgent": "#ed8796",
        "border_active": "accent",
        "border_inactive": "#494d64",
        "opacity": 0.78,
    },
    "shape": {
        "radius": 12,
        "border": 2,
        "gaps_in": 5,
        "gaps_out": 10,
        "bar": "floating",  # floating | docked
        "bar_position": "top",  # top | bottom
        "bar_height": 34,
        "widget": "pill",  # pill | rounded | square
    },
    "font": {"ui": "Inter", "mono": "JetBrainsMono Nerd Font", "size": 13},
    "effects": {"blur": True, "shadow": True, "dim_inactive": False, "animation": "smooth",
                "active_opacity": 1.0, "inactive_opacity": 1.0},
    "hooks": {"apply": []},
}

# Applied when no theme has been chosen yet (keep in sync with hypr settings.lua).
DEFAULT_ID = "moonlantern"

HEX = re.compile(r"^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$")


class ThemeError(RuntimeError):
    pass


def _merge(dst: dict[str, Any], src: dict[str, Any]) -> dict[str, Any]:
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            _merge(dst[k], v)
        else:
            dst[k] = v
    return dst


def _rgba(hex_color: str, alpha: float) -> str:
    h = hex_color.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"


def find(theme_id: str) -> Path:
    path = paths.search("themes", theme_id, "theme.toml")
    if path is None:
        raise ThemeError(f"theme not found: {theme_id} (available: {', '.join(available())})")
    return path


def available() -> list[str]:
    return paths.available("themes", "theme.toml")


def resolve(theme_id: str) -> dict[str, Any]:
    path = find(theme_id)
    with path.open("rb") as f:
        raw = tomllib.load(f)
    t = _merge(copy.deepcopy(DEFAULTS), raw)
    t["id"] = theme_id
    t["meta"]["name"] = t["meta"]["name"] or theme_id

    pal = t["palette"]
    for key, value in list(pal.items()):
        if isinstance(value, str) and value in pal and key != value:
            pal[key] = pal[value]  # allow references like border_active = "accent"
    for key, value in pal.items():
        if key == "bar_opacity":
            if isinstance(value, bool) or not isinstance(value, (int, float)) or not 0 <= value <= 1:
                raise ThemeError(f"{path}: palette.bar_opacity must be between 0 and 1")
        elif key != "opacity" and not HEX.match(str(value)):
            raise ThemeError(f"{path}: palette.{key} must be #rrggbb[aa], got {value!r}")
    pal["bg_rgba"] = _rgba(pal["bg"], pal["opacity"])

    wp = t["wallpaper"]
    if wp["path"]:
        resolved = paths.expand(wp["path"], path.parent)
        wp["path"] = str(resolved) if resolved.is_file() else ""
        if not resolved.is_file():
            wp["missing"] = str(resolved)

    if t["shape"]["bar"] not in ("floating", "docked"):
        raise ThemeError(f"{path}: shape.bar must be floating|docked")
    t["shape"]["widget_radius"] = {"pill": 999, "rounded": max(4, t["shape"]["radius"] // 2), "square": 0}.get(
        t["shape"]["widget"], 999
    )
    t["source"] = str(path)
    t["rev"] = time.time_ns()
    return t


# ---- outputs ------------------------------------------------------------------


def _hypr_color(hex_color: str) -> str:
    h = hex_color.lstrip("#")
    return f"rgba({h}{'ff' if len(h) == 6 else ''})"


def _lua(value: Any, indent: int = 0) -> str:
    pad = "\t" * (indent + 1)
    if isinstance(value, dict):
        items = ",\n".join(f"{pad}{k} = {_lua(v, indent + 1)}" for k, v in value.items())
        return "{\n" + items + "\n" + "\t" * indent + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    return json.dumps(str(value), ensure_ascii=False)


def to_lua(t: dict[str, Any]) -> str:
    pal, shape, fx = t["palette"], t["shape"], t["effects"]
    data = {
        "id": t["id"],
        "palette": {
            "accent": _hypr_color(pal["accent"]),
            "accent_alt": _hypr_color(pal["accent_alt"]),
            "border_active": _hypr_color(pal["border_active"]),
            "border_inactive": _hypr_color(pal["border_inactive"]),
            "shadow": _hypr_color(pal["bg"]),
        },
        "shape": {k: shape[k] for k in ("radius", "border", "gaps_in", "gaps_out")},
        "effects": fx,
    }
    return f"-- generated by `omh theme apply {t['id']}`; do not edit\nreturn {_lua(data)}\n"


def _write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = None
    try:
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=path.parent, delete=False) as f:
            temp = Path(f.name)
            f.write(text)
        os.replace(temp, path)
    finally:
        if temp is not None:
            temp.unlink(missing_ok=True)


@contextmanager
def state_lock():
    paths.STATE.mkdir(parents=True, exist_ok=True)
    with (paths.STATE / "appearance.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def in_ohmyhypr_session() -> bool:
    try:
        out = subprocess.run(["hyprctl", "repl", "return OHMYHYPR_ROOT"], capture_output=True, text=True, timeout=3)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False
    return out.returncode == 0 and out.stdout.strip() not in ("", "nil")


def publish(t: dict[str, Any]) -> dict[str, Any]:
    """Publish a complete resolved appearance; caller holds state_lock()."""
    t["rev"] = time.time_ns()
    t["palette"]["bg_rgba"] = _rgba(t["palette"]["bg"], t["palette"]["opacity"])
    color_state = {"source": t.get("palette_source", "theme"), "wallpaper": t.get("palette_wallpaper", t["wallpaper"]["path"]),
                   "dark": t["meta"]["dark"], "colors": t["palette"], "rev": t["rev"]}
    _write_atomic(paths.THEME_LUA, to_lua(t))
    _write_atomic(paths.PALETTE_JSON, json.dumps(color_state, ensure_ascii=False, indent=2))
    _write_atomic(paths.THEME_JSON, json.dumps(t, ensure_ascii=False, indent=2))

    report: dict[str, Any] = {"theme": t["id"], "hyprland": "skipped (not an ohmyhypr session)", "hooks": []}
    if in_ohmyhypr_session():
        out = subprocess.run(["hyprctl", "reload", "config-only"], capture_output=True, text=True)
        report["hyprland"] = out.stdout.strip() or out.stderr.strip()
        if out.returncode:
            report["hyprland_error"] = out.returncode

    env = {**os.environ, "OHMYHYPR_THEME_JSON": str(paths.THEME_JSON), "OHMYHYPR_THEME": t["id"],
           "OHMYHYPR_PALETTE_JSON": str(paths.PALETTE_JSON)}
    for hook in t["hooks"]["apply"]:
        res = subprocess.run(hook, shell=True, env=env, capture_output=True, text=True, timeout=30)
        report["hooks"].append({"cmd": hook, "rc": res.returncode})
    return report


def apply(theme_id: str) -> dict[str, Any]:
    t = resolve(theme_id)
    warning = None
    t["palette_source"] = "theme"
    if t["wallpaper"]["path"]:
        try:
            t["palette"] = palette.extract(Path(t["wallpaper"]["path"]), t["meta"]["dark"], t["palette"]["opacity"])
            t["palette_source"] = "wallpaper"
        except palette.PaletteError as e:
            warning = str(e) + "; using theme colors"
    elif t["wallpaper"].get("missing"):
        warning = f"wallpaper not found: {t['wallpaper']['missing']} (gradient fallback)"
    with state_lock():
        report = publish(t)
    if warning:
        report["warning"] = warning
    return report


def current() -> dict[str, Any] | None:
    try:
        return json.loads(paths.THEME_JSON.read_text())
    except (OSError, json.JSONDecodeError):
        return None


def summary() -> list[dict[str, Any]]:
    cur = (current() or {}).get("id")
    out = []
    for theme_id in available():
        try:
            t = resolve(theme_id)
        except (ThemeError, tomllib.TOMLDecodeError) as e:
            out.append({"id": theme_id, "error": str(e)})
            continue
        out.append({
            "id": theme_id,
            "name": t["meta"]["name"],
            "description": t["meta"]["description"],
            "current": theme_id == cur,
            "wallpaper": t.get("palette_wallpaper", t["wallpaper"]["path"]),
            "palette": {k: t["palette"][k] for k in ("bg", "surface", "fg", "accent", "accent_alt")},
            "radius": t["shape"]["radius"],
        })
    return out
