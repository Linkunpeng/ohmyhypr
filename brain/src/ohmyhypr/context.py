"""Desktop context snapshot: what the user is looking at right now.

Everything here is treated as untrusted data when handed to a model.
"""

from __future__ import annotations

import subprocess
from datetime import datetime
from typing import Any

from . import hypr

CLIP_LIMIT = 2000


def _paste(*flags: str) -> str | None:
    try:
        out = subprocess.run(
            ["wl-paste", "--no-newline", "--type", "text", *flags],
            capture_output=True,
            text=True,
            timeout=2,
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return None
    if out.returncode != 0 or not out.stdout:
        return None
    return out.stdout[:CLIP_LIMIT]


def _window_summary(win: dict[str, Any]) -> dict[str, Any]:
    return {
        "class": win.get("class"),
        "title": win.get("title"),
        "workspace": (win.get("workspace") or {}).get("name"),
        "floating": win.get("floating"),
        "pid": win.get("pid"),
    }


def snapshot(include_clipboard: bool = True) -> dict[str, Any]:
    ctx: dict[str, Any] = {"time": datetime.now().astimezone().isoformat(timespec="seconds")}
    try:
        active = hypr.active_window()
        ctx["active_window"] = _window_summary(active) if active else None
        ctx["windows"] = [_window_summary(w) for w in hypr.clients() if w.get("mapped", True)]
        ctx["workspaces"] = sorted(
            ({"name": w["name"], "windows": w["windows"]} for w in hypr.workspaces()),
            key=lambda w: w["name"],
        )
    except hypr.HyprError as e:
        ctx["hyprland_error"] = str(e)
    if include_clipboard:
        ctx["clipboard"] = _paste()
        ctx["selection"] = _paste("--primary")
    return ctx
