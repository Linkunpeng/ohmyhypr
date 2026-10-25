#!/usr/bin/env bash
# Make ohmyhypr the live Hyprland config, or roll back.
#
#   scripts/switch.sh enable    back up ~/.config/hypr/hyprland.lua, point it at this repo
#   scripts/switch.sh disable   restore the most recent backup
#   scripts/switch.sh status
#
# Nothing is reloaded automatically: run `hyprctl reload` (or log out/in) afterwards.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HYPR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
TARGET="$HYPR/hyprland.lua"
MARK="-- ohmyhypr:switch"

is_enabled() { [[ -f "$TARGET" ]] && head -1 "$TARGET" | grep -qF -- "$MARK"; }

case "${1:-status}" in
  enable)
    if is_enabled; then echo "already enabled"; exit 0; fi
    out="$(Hyprland --verify-config -c "$REPO/hypr/hyprland.lua" 2>&1 | tail -1)"
    [[ "$out" == "config ok" ]] || { echo "ohmyhypr config invalid: $out"; exit 1; }
    if [[ ! -f "$REPO/hypr/lua/omh/local.lua" ]]; then
      cp "$REPO/hypr/lua/omh/local.example.lua" "$REPO/hypr/lua/omh/local.lua"
      echo "created hypr/lua/omh/local.lua from the example — check monitors before reloading"
    fi
    backup="$TARGET.pre-ohmyhypr-$(date +%Y%m%d-%H%M%S)"
    [[ -f "$TARGET" ]] && cp -a "$TARGET" "$backup" && echo "backup: $backup"
    printf '%s\ndofile("%s/hypr/hyprland.lua")\n' "$MARK" "$REPO" > "$TARGET"
    echo "enabled. Apply with: hyprctl reload   (roll back: $0 disable)"
    ;;
  disable)
    is_enabled || { echo "not enabled"; exit 0; }
    latest="$(ls -t "$TARGET".pre-ohmyhypr-* 2>/dev/null | head -1 || true)"
    [[ -n "$latest" ]] || { echo "no backup found next to $TARGET"; exit 1; }
    cp -a "$latest" "$TARGET"
    echo "restored $latest. Apply with: hyprctl reload"
    ;;
  status)
    if is_enabled; then echo "enabled ($TARGET → $REPO)"; else echo "disabled"; fi
    ;;
  *) echo "usage: $0 enable|disable|status"; exit 2 ;;
esac
