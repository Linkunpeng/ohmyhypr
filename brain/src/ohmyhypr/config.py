"""User config: ~/.config/ohmyhypr/config.toml merged over built-in defaults."""

from __future__ import annotations

import os
import tomllib
from pathlib import Path
from typing import Any

CONFIG_PATH = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "ohmyhypr" / "config.toml"

DEFAULTS: dict[str, Any] = {
    "router": {
        # "local" | "cloud". Screen / clipboard context never leaves the machine
        # unless cloud_context is enabled.
        "default": "local",
        "cloud_context": False,
    },
    "local": {
        "base_url": "http://127.0.0.1:8080/v1",
        "chat_model": "llm-smart",
        "vision_model": "vlm-default",
        "asr_model": "asr-default",
        "tts_model": "tts-default",
        "timeout": 120,
    },
    "gpu_keeper": {
        "url": "http://127.0.0.1:6101",
        "owner": "LOCALAI",
        "enabled": True,
        # Interactive use: give up quickly instead of hanging the UI.
        "wait_timeout": 10,
        "ttl": 120,
        # When the keeper is unreachable: False = run unmanaged, True = refuse.
        "required": False,
    },
    "cloud": {
        "command": ["claude", "-p"],
    },
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
