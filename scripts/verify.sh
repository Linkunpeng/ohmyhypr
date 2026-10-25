#!/usr/bin/env bash
# Static checks for every layer. Exit non-zero on the first failure.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> hypr: Hyprland --verify-config"
out="$(Hyprland --verify-config -c "$REPO/hypr/hyprland.lua" 2>&1 | tail -1)"
echo "    $out"
[[ "$out" == "config ok" ]]

echo "==> brain: py_compile"
python3 -m py_compile "$REPO"/brain/src/ohmyhypr/*.py
echo "    ok"

if command -v ruff >/dev/null; then
  echo "==> brain: ruff"
  ruff check "$REPO/brain/src"
fi
