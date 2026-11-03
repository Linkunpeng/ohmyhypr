"""`omh doctor`: check every dependency of the desktop and report."""

from __future__ import annotations

import shutil
import subprocess
from typing import Any

OK, WARN, FAIL = "✔", "!", "✘"

BINARIES = {
    "Hyprland": True,
    "hyprctl": True,
    "qs": True,
    "wl-paste": True,
    "grim": False,
    "slurp": False,
    "satty": False,
    "wl-copy": False,
    "xdg-user-dir": False,
    "cliphist": False,
    "wtype": False,
    "notify-send": False,
    "ffmpeg": False,
    "hyprlock": False,
    "hypridle": False,
    "loginctl": False,
}


def run(cfg: dict[str, Any]) -> int:
    failed = 0
    for name, required in BINARIES.items():
        path = shutil.which(name)
        mark = OK if path else (FAIL if required else WARN)
        failed += mark == FAIL
        print(f" {mark} {name:<12} {path or ('missing (required)' if required else 'missing')}")

    if shutil.which("Hyprland"):
        ver = subprocess.run(["Hyprland", "--version"], capture_output=True, text=True).stdout
        print(f"   {ver.splitlines()[0] if ver else '?'}")

    from . import providers

    try:
        name, provider = providers.resolve(cfg)
        print(f" {OK} {'AI provider':<12} {name} ({provider['type']}, {provider['model']})")
    except (providers.ProviderError, ValueError) as e:
        print(f" {WARN} {'AI provider':<12} {e}")

    command = cfg.get("avatar", {}).get("command", [])
    if command:
        import os
        executable = os.path.expanduser(os.path.expandvars(command[0]))
        found = shutil.which(executable)
        print(f" {OK if found else WARN} {'avatar':<12} {found or 'adapter command not found'}")
    else:
        print(f" {WARN} {'avatar':<12} adapter not configured (optional)")

    print()
    print("all required dependencies present" if not failed else f"{failed} required missing")
    return 1 if failed else 0
