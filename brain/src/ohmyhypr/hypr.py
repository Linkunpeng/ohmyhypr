"""Thin wrapper over hyprctl.

Hyprland 0.56 with a Lua config takes Lua expressions for `dispatch`
(e.g. ``hl.dsp.focus({ workspace = 3 })``), not the legacy syntax.
"""

from __future__ import annotations

import json
import subprocess
from typing import Any


class HyprError(RuntimeError):
    pass


def _run(*args: str) -> str:
    try:
        out = subprocess.run(["hyprctl", *args], capture_output=True, text=True, timeout=5)
    except FileNotFoundError as e:
        raise HyprError("hyprctl not found") from e
    if out.returncode != 0:
        raise HyprError(out.stderr.strip() or out.stdout.strip())
    return out.stdout


def query(what: str) -> Any:
    return json.loads(_run("-j", what))


def active_window() -> dict[str, Any] | None:
    win = query("activewindow")
    return win or None


def clients() -> list[dict[str, Any]]:
    return query("clients")


def workspaces() -> list[dict[str, Any]]:
    return query("workspaces")


def monitors() -> list[dict[str, Any]]:
    return query("monitors")


def dispatch(lua_expr: str) -> str:
    """Run a Lua dispatcher expression, e.g. ``hl.dsp.focus({ workspace = 2 })``."""
    out = _run("dispatch", lua_expr).strip()
    if out != "ok":
        raise HyprError(out)
    return out
