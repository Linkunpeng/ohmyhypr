"""Recover active tray items that missed a watcher restart."""
from __future__ import annotations

import json
import re
import subprocess
from typing import Any

WATCHER = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
ITEM = "org.kde.StatusNotifierItem"
ITEM_PATH = "/StatusNotifierItem"
ITEM_NAME = re.compile(r"^org\.kde\.StatusNotifierItem-[0-9]+-[0-9]+$")


def _bus(*args: str) -> Any:
    result = subprocess.run(["busctl", "--user", "--json=short", *args], capture_output=True, text=True, timeout=3)
    if result.returncode:
        raise OSError("D-Bus request failed")
    return json.loads(result.stdout) if result.stdout.strip() else None


def recover() -> int:
    """Re-register active, conventionally named items only when absent."""
    try:
        names = _bus("list")
        registered = _bus("get-property", WATCHER, WATCHER_PATH, WATCHER, "RegisteredStatusNotifierItems")
        if not isinstance(names, list) or not isinstance(registered["data"], list):
            return 0
        existing = {entry.split("/", 1)[0] for entry in registered["data"] if isinstance(entry, str)}
    except (OSError, subprocess.TimeoutExpired, ValueError, TypeError, KeyError):
        return 0
    count = 0
    for entry in names:
        if not isinstance(entry, dict):
            continue
        name = entry.get("name", "")
        owner = entry.get("connection", "")
        if not isinstance(name, str) or not ITEM_NAME.fullmatch(name) or name in existing or (owner and owner in existing):
            continue
        try:
            status = _bus("get-property", name, ITEM_PATH, ITEM, "Status")
            if status.get("data") not in ("Active", "NeedsAttention"):
                continue
            _bus("call", WATCHER, WATCHER_PATH, WATCHER, "RegisterStatusNotifierItem", "s", name)
        except (OSError, subprocess.TimeoutExpired, ValueError, TypeError, AttributeError):
            continue
        existing.add(name)
        if owner:
            existing.add(owner)
        count += 1
    return count
