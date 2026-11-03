"""User config: ~/.config/ohmyhypr/config.toml merged over built-in defaults."""

from __future__ import annotations

import os
import tomllib
from pathlib import Path
from typing import Any

CONFIG_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ohmyhypr" / "config.toml"

DEFAULTS: dict[str, Any] = {
    "ai": {"default_provider": "openai", "include_context": False},
    "providers": {},
    "wallpaper": {"directory": "~/Pictures/wallpapers"},
    "lock": {"timeout_seconds": 600, "before_sleep": True},
}


def _merge(dst: dict[str, Any], src: dict[str, Any]) -> dict[str, Any]:
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            _merge(dst[key], value)
        else:
            dst[key] = value
    return dst


def load() -> dict[str, Any]:
    import copy

    cfg = copy.deepcopy(DEFAULTS)
    if CONFIG_PATH.exists():
        with CONFIG_PATH.open("rb") as f:
            _merge(cfg, tomllib.load(f))
    return cfg
