#!/usr/bin/env bash
# Open the existing notification center without taking over the notification service.
set -euo pipefail
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"

if command -v qs >/dev/null 2>&1; then
    targets="$(qs ipc -p "$config_dir" show 2>/dev/null || true)"
    if [[ "$targets" == *"target notifications"* ]]; then
        exec qs ipc -p "$config_dir" call notifications toggleNotifications "${1:-}"
    elif [[ "$targets" == *"function toggleNotifications("* ]]; then
        exec qs ipc -p "$config_dir" call agentdesk toggleNotifications "${1:-}"
    elif [[ "$targets" == *"function toggleCenter(): void"* ]]; then
        # Older ORBIT versions open the task center; select its Notifications tab.
        exec qs ipc -p "$config_dir" call agentdesk toggleCenter
    fi
fi
if command -v swaync-client >/dev/null 2>&1; then
    exec swaync-client --toggle-panel
fi
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a ohmyhypr "通知中心不可用" "请启动通知中心服务。"
fi
exit 1
