"""Filesystem layout shared by every ohmyhypr component."""

from __future__ import annotations

import os
from pathlib import Path


def _xdg(var: str, fallback: str) -> Path:
    return Path(os.environ.get(var) or Path.home() / fallback)


# brain/src/ohmyhypr/paths.py → repo root (also valid for editable installs)
REPO = Path(os.environ.get("OHMYHYPR_ROOT") or Path(__file__).resolve().parents[3]).expanduser()
CONFIG = _xdg("XDG_CONFIG_HOME", ".config") / "ohmyhypr"
STATE = _xdg("XDG_STATE_HOME", ".local/state") / "ohmyhypr"
RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/tmp/ohmyhypr-{os.getuid()}") / "ohmyhypr"

THEME_JSON = STATE / "theme.json"
THEME_LUA = STATE / "theme.lua"
AVATAR_SOCKET = RUNTIME / "avatar.sock"


def search(kind: str, name: str, filename: str) -> Path | None:
    """User dir (~/.config/ohmyhypr/<kind>) wins over the repo's built-ins."""
    for base in (CONFIG / kind, REPO / kind):
        candidate = base / name / filename
        if candidate.is_file():
            return candidate
    return None


def available(kind: str, filename: str) -> list[str]:
    names: set[str] = set()
    for base in (CONFIG / kind, REPO / kind):
        if base.is_dir():
            names.update(p.parent.name for p in base.glob(f"*/{filename}"))
    return sorted(names)


def expand(path: str, base: Path) -> Path:
    p = Path(path).expanduser()
    return p if p.is_absolute() else (base / p)
