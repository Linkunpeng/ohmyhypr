#!/usr/bin/env bash
# Run ohmyhypr in a nested Hyprland window inside the current session.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

Hyprland --verify-config -c "$REPO/hypr/hyprland.lua" | tail -1
OHMYHYPR_NESTED=1 exec Hyprland -c "$REPO/hypr/hyprland.lua"
