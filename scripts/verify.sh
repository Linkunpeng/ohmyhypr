#!/usr/bin/env bash
# Static checks for every layer. Exit non-zero on the first failure.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> hypr: Hyprland --verify-config"
out="$(Hyprland --verify-config -c "$REPO/hypr/hyprland.lua" 2>&1 | tail -1)"
echo "    $out"
[[ "$out" == "config ok" ]]

echo "==> brain: py_compile"
python3 -m py_compile "$REPO"/brain/src/ohmyhypr/*.py "$REPO"/brain/src/ohmyhypr/avatar/*.py
echo "    ok"

echo "==> brain: provider tests"
PYTHONPATH="$REPO/brain/src" python3 -m unittest discover -s "$REPO/brain/tests"

if command -v ruff >/dev/null; then
  echo "==> brain: ruff"
  ruff check "$REPO/brain/src"
fi

echo "==> themes: resolve all"
PYTHONPATH="$REPO/brain/src" python3 - <<'PY'
from ohmyhypr import theme
for t in theme.available():
    theme.resolve(t)
    print(f"    {t} ok")
PY
