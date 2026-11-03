#!/usr/bin/env bash
# Toggle the notification center belonging to this checkout.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec qs ipc -p "$repo/shell" call notifications toggleNotifications "${1:-}"
