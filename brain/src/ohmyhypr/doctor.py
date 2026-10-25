"""`omh doctor`: check every dependency of the desktop and report."""

from __future__ import annotations

import shutil
import subprocess
import urllib.request
from typing import Any

OK, WARN, FAIL = "✔", "!", "✘"

BINARIES = {
    "Hyprland": True,
    "hyprctl": True,
    "qs": True,
    "wl-paste": True,
    "grim": False,
    "slurp": False,
    "cliphist": False,
    "wtype": False,
    "notify-send": False,
    "claude": False,
    "npm": False,
}

# Avatar host runs under the system python (PyGObject); probe it there.
AVATAR_PROBE = """
import gi
gi.require_version('Gtk', '3.0'); gi.require_version('WebKit2', '4.1'); gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, WebKit2, GtkLayerShell
import cairo
"""


def _http_ok(url: str) -> bool:
    try:
        with urllib.request.urlopen(url, timeout=3) as resp:
            return 200 <= resp.status < 300
    except Exception:  # noqa: BLE001
        return False


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

    base = cfg["local"]["base_url"].removesuffix("/v1").rstrip("/")
    for label, url in [
        ("LocalAI", f"{base}/readyz"),
        ("GPU Keeper", f"{cfg['gpu_keeper']['url'].rstrip('/')}/status"),
    ]:
        mark = OK if _http_ok(url) else WARN
        print(f" {mark} {label:<12} {url}")

    from . import paths

    probe = subprocess.run(["/usr/bin/python3", "-c", AVATAR_PROBE], capture_output=True, text=True)
    mark = OK if probe.returncode == 0 else WARN
    detail = "gtk3 + webkit2gtk-4.1 + gtk-layer-shell + pycairo" if probe.returncode == 0 else probe.stderr.strip().splitlines()[-1:]
    print(f" {mark} {'avatar host':<12} {detail}")
    built = (paths.REPO / "avatar" / "dist" / "main.js").is_file()
    print(f" {OK if built else WARN} {'avatar build':<12} {'avatar/dist' if built else 'not built (make avatar)'}")

    print()
    print("all required dependencies present" if not failed else f"{failed} required missing")
    return 1 if failed else 0
