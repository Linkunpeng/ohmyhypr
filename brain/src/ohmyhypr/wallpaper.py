"""Set a wallpaper and derive a palette while preserving the active theme's shape."""

from __future__ import annotations

import urllib.parse
from pathlib import Path
from typing import Any

from . import palette, theme


class WallpaperError(RuntimeError):
    pass


def image_path(value: str) -> Path:
    if value.startswith("file:"):
        url = urllib.parse.urlsplit(value)
        if url.netloc not in ("", "localhost") or url.query or url.fragment:
            raise WallpaperError("wallpaper must be a local file URL")
        value = urllib.parse.unquote(url.path)
    return Path(value).expanduser().resolve()


def set_wallpaper(value: str, fit: str | None = None, screen: str | None = None) -> dict[str, Any]:
    path = image_path(value)
    if screen and screen not in {m["name"] for m in monitors()}:
        raise WallpaperError(f"screen is not connected: {screen}")
    with theme.state_lock():
        t = theme.current() or theme.resolve("sandrone")
        try:
            colors = palette.extract(path, t["meta"]["dark"], t["palette"]["opacity"])
        except palette.PaletteError as e:
            raise WallpaperError(str(e)) from e
        selected = {"path": str(path), "fit": fit or t["wallpaper"].get("fit", "cover")}
        if screen:
            t.setdefault("wallpapers", {})[screen] = selected
        else:
            t["wallpaper"] = selected
            t.pop("wallpapers", None)
        t["palette_wallpaper"] = str(path)
        t["palette"] = colors
        t["palette_source"] = "wallpaper"
        report = theme.publish(t)
    report["wallpaper"] = str(path)
    report["screen"] = screen or "all"
    return report


def monitors() -> list[dict[str, Any]]:
    import json
    import subprocess
    try:
        result = subprocess.run(["hyprctl", "-j", "monitors"], capture_output=True, text=True, timeout=3)
        if result.returncode:
            raise WallpaperError("cannot read connected screens")
        return json.loads(result.stdout)
    except (OSError, ValueError, subprocess.TimeoutExpired) as e:
        raise WallpaperError("cannot read connected screens") from e


def catalog(cfg: dict[str, Any], screen: str | None = None) -> dict[str, Any]:
    root = Path(cfg.get("wallpaper", {}).get("directory", "~/Pictures/wallpapers")).expanduser().resolve()
    connected = monitors()
    target = screen or next((m["name"] for m in connected if m.get("focused")), "")
    state = theme.current() or {}
    current = state.get("wallpapers", {}).get(target, state.get("wallpaper", {})).get("path", "")
    items = []
    if root.is_dir():
        for path in sorted(root.rglob("*")):
            if path.is_file() and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif"}:
                items.append({"name": str(path.relative_to(root)), "path": str(path), "url": path.as_uri(),
                              "current": str(path) == current})
    return {"directory": str(root), "screen": target, "items": items,
            "error": "" if root.is_dir() else "壁纸目录不存在，请创建目录或修改配置"}
