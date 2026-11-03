#!/bin/bash
# ================================================================
#  下拉终端 (dropdown terminal) — Hyprland 0.56 + Lua 配置版
#  用法: ./Dropterminal.sh [-d] <terminal_command>
#        例: ./Dropterminal.sh -d kitty
#            ./Dropterminal.sh "kitty -e zsh"
#
#  0.55+ 起 hyprlang 与旧 dispatcher 字符串 (movewindowpixel /
#  movetoworkspacesilent / pin / focuswindow / "[float; size ..]")
#  全部失效，dispatch 现在只是 hl.dispatch(...) 的包装。
#  本脚本改用 `hyprctl repl 'hl.dispatch(hl.dsp.*)'`：
#    exec_cmd  -> 直接以浮窗+目标尺寸生成到暂存工作区（不可见）
#    float/move/resize/center/pin/focus -> hl.dsp.window.* / hl.dsp.focus
#  居中不自己算坐标（保留区域会算错），改用 window.center() 后回读 at。
#  依赖: jq
# ================================================================

DEBUG=false
SPECIAL_WS="special:scratchpad"
ADDR_FILE="/tmp/dropdown_terminal_addr"

# 尺寸（屏幕百分比）；位置由 window.center() 决定
WIDTH_PERCENT=50
HEIGHT_PERCENT=50

# 滑入滑出动画
SLIDE_STEPS=5
SLIDE_DELAY=0.02
OFFSCREEN_GAP=50

# ---------------------------------------------------------------
# 环境：保证 hyprctl 找得到当前 Hyprland 实例
# ---------------------------------------------------------------
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
  # 取最近活跃的实例目录（含 .socket.sock）
  HYPRLAND_INSTANCE_SIGNATURE=$(
    for d in "$XDG_RUNTIME_DIR"/hypr/*/; do
      [ -S "$d/.socket.sock" ] && echo "$(stat -c %Y "$d/.socket.sock") ${d%/}"
    done | sort -rn | head -1 | awk '{print $2}' | sed 's#.*/##'
  )
  export HYPRLAND_INSTANCE_SIGNATURE
fi

# ---------------------------------------------------------------
# 参数
# ---------------------------------------------------------------
if [ "$1" = "-d" ]; then
  DEBUG=true
  shift
fi
TERMINAL_CMD="$1"

debug_echo() {
  # 一律写 stderr：stdout 只用于返回数据
  [ "$DEBUG" = true ] && echo "[dd] $*" >&2
  return 0
}

if [ -z "$TERMINAL_CMD" ]; then
  cat >&2 <<EOF
Missing terminal command. Usage: $0 [-d] <terminal_command>
例如:  $0 kitty
       $0 -d "kitty -e zsh"
EOF
  exit 1
fi

# 终端窗口类名（kitty -> kitty），用来确认 ADDR_FILE 里记的窗口确实是我们的终端
TERM_CLASS=$(basename "${TERMINAL_CMD%% *}")

command -v jq >/dev/null 2>&1 || { echo "需要 jq: sudo pacman -S jq" >&2; exit 1; }

# ---------------------------------------------------------------
# 0.56 Lua dispatcher 封装
# ---------------------------------------------------------------
lua_dispatch() {
  local code="$1" out
  out=$(hyprctl repl "hl.dispatch($code)" 2>&1)
  debug_echo "$code -> $out"
  case "$out" in
    *"expected"*|*error*|*Invalid*|*unrecognized*) return 1 ;;
  esac
  return 0
}

# Lua 字符串转义（用于把 shell 变量塞进 Lua 双引号串）
lua_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

clients_json() { hyprctl clients -j; }

# Hyprland 的窗口地址是堆指针，终端关掉后会被别的新窗口复用
# （例如反复显示/隐藏、重启的 myhypr-avatar）。只比地址会把别人的窗口当成下拉终端，
# 所以同时校验类名和 pid。
addr_exists() { # addr [pid]
  local addr="$1" pid="$2"
  [ -n "$addr" ] || return 1
  clients_json | jq -e --arg A "$addr" --arg P "$pid" --arg C "$TERM_CLASS" \
    'any(.[]; .address == $A and (.class|ascii_downcase) == ($C|ascii_downcase)
              and ($P == "" or (.pid|tostring) == $P))' >/dev/null 2>&1
}

# 记录 "地址 pid"
save_addr() {
  local addr="$1"
  echo "$addr $(window_field "$addr" pid)" >"$ADDR_FILE"
}

window_field() { # addr field（支持 workspace.name 这类嵌套路径）
  clients_json | jq -r --arg A "$1" --arg F "$2" '.[] | select(.address == $A) | getpath($F|split("."))' 2>/dev/null
}

# 「画面内」判定：pinned 且不在暂存区
window_visible() {
  local addr="$1"
  clients_json | jq -e --arg A "$addr" \
    'any(.[]; .address == $A and .pinned == true and (.workspace.name != "special:scratchpad"))' >/dev/null 2>&1
}

# ---------------------------------------------------------------
# 几何 / 目标尺寸
# ---------------------------------------------------------------
target_size() { # -> "W H"（当前聚焦显示器的百分比）
  local geom w h
  geom=$(hyprctl monitors -j | jq -r '([.[]|select(.focused)]|first // .[0]) | "\(.width) \(.height)"')
  w=$(echo "$geom" | cut -d' ' -f1)
  h=$(echo "$geom" | cut -d' ' -f2)
  echo "$((w * WIDTH_PERCENT / 100)) $((h * HEIGHT_PERCENT / 100))"
}

current_ws() { hyprctl activeworkspace -j | jq -r '.id'; }

# ---------------------------------------------------------------
# 动画：滑入 / 滑出
# ---------------------------------------------------------------
animate_to() { # addr target_x target_y steps
  local addr="$1" tx="$2" ty="$3" steps="$4"
  local cx cy sy step i
  cx=$(window_field "$addr" at | jq -r '.[0]')
  cy=$(window_field "$addr" at | jq -r '.[1]')
  [ -z "$cx" ] && return 1
  step=$(( (ty - cy) / steps ))
  for i in $(seq 1 "$steps"); do
    lua_dispatch "hl.dsp.window.move({ x=$cx, y=$((cy + step * i)), window=\"address:$addr\" })" >/dev/null
    sleep "$SLIDE_DELAY"
  done
  lua_dispatch "hl.dsp.window.move({ x=$tx, y=$ty, window=\"address:$addr\" })" >/dev/null
}

# ---------------------------------------------------------------
# 显示 / 收起
# ---------------------------------------------------------------
show_terminal() {
  local addr="$1" w="$2" h="$3" ws tx ty start_y at size pw ph
  ws=$(current_ws)

  lua_dispatch "hl.dsp.window.float({ action=\"enable\", window=\"address:$addr\" })"
  lua_dispatch "hl.dsp.window.move({ workspace=$ws, follow=false, window=\"address:$addr\" })"
  lua_dispatch "hl.dsp.window.resize({ x=$w, y=$h, window=\"address:$addr\" })"

  # 居中：交给 Hyprland（自己算会忽略保留区域），再回读 at 作为动画终点
  lua_dispatch "hl.dsp.window.center({ window=\"address:$addr\" })"

  # 轮询到坐标稳定（有动画时 at 是渐变的）
  local prev="" cur="" n=0
  while [ "$n" -lt 20 ]; do
    cur=$(window_field "$addr" at)
    [ -n "$prev" ] && [ "$cur" = "$prev" ] && break
    prev="$cur"; n=$((n + 1)); sleep 0.05
  done
  tx=$(echo "$cur" | jq -r '.[0]')
  ty=$(echo "$cur" | jq -r '.[1]')
  debug_echo "居中后 at=$cur"

  # 滑入：先放到屏幕上方，再逐帧下移
  start_y=$((ty - h - OFFSCREEN_GAP))
  lua_dispatch "hl.dsp.window.move({ x=$tx, y=$start_y, window=\"address:$addr\" })" >/dev/null
  animate_to "$addr" "$tx" "$ty" "$SLIDE_STEPS"

  lua_dispatch "hl.dsp.window.pin({ action=\"enable\", window=\"address:$addr\" })"
  lua_dispatch "hl.dsp.focus({ window=\"address:$addr\" })"

  at=$(window_field "$addr" at); size=$(window_field "$addr" size)
  pw=$(window_field "$addr" pinned)
  debug_echo "显示完成: at=$at size=$size pinned=$pw ws=$(window_field "$addr" workspace.name)"
  return 0
}

hide_terminal() {
  local addr="$1" at size w h cx cy end_y
  at=$(window_field "$addr" at)
  size=$(window_field "$addr" size)
  cx=$(echo "$at" | jq -r '.[0]'); cy=$(echo "$at" | jq -r '.[1]')
  h=$(echo "$size" | jq -r '.[1]')
  end_y=$((cy - h - OFFSCREEN_GAP))

  animate_to "$addr" "$cx" "$end_y" "$SLIDE_STEPS"
  sleep 0.05
  # 顺序很重要：pinned 的窗口移不进 special，必须先解 pin
  lua_dispatch "hl.dsp.window.pin({ action=\"disable\", window=\"address:$addr\" })"
  lua_dispatch "hl.dsp.window.move({ workspace=\"$SPECIAL_WS\", follow=false, window=\"address:$addr\" })"
  debug_echo "已收起: ws=$(window_field "$addr" workspace.name) pinned=$(window_field "$addr" pinned)"
  return 0
}

# ---------------------------------------------------------------
# 生成新终端
# ---------------------------------------------------------------
spawn_terminal() {
  local w h before after new_addr i
  read -r w h <<<"$(target_size)"
  debug_echo "目标尺寸: ${w}x${h}"

  before=$(clients_json | jq -r '.[].address' | sort)
  lua_dispatch "hl.dsp.exec_cmd(\"$(lua_escape "$TERMINAL_CMD")\", { float = true, size = { $w, $h }, workspace = \"$SPECIAL_WS silent\" })" \
    || { echo "生成终端失败（exec_cmd）" >&2; return 1; }

  # 只认类名匹配的新窗口：等待期间别的程序（如 avatar）也可能刚好开出窗口
  new_addr=""
  for i in $(seq 1 40); do
    sleep 0.05
    after=$(clients_json | jq -r --arg C "$TERM_CLASS" \
      '.[] | select((.class|ascii_downcase) == ($C|ascii_downcase)) | .address' | sort)
    new_addr=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
    [ -n "$new_addr" ] && break
  done

  if [ -z "$new_addr" ]; then
    # 兜底：暂存区里找一个类名匹配的窗口（不碰其他工作区里的普通终端）
    new_addr=$(clients_json | jq -r --arg C "$TERM_CLASS" --arg W "$SPECIAL_WS" \
      '.[] | select((.class|ascii_downcase) == ($C|ascii_downcase) and .workspace.name == $W) | .address' | head -1)
  fi

  if [ -z "$new_addr" ] || [ "$new_addr" = "null" ]; then
    echo "未能获取新终端窗口地址" >&2
    return 1
  fi

  save_addr "$new_addr"
  debug_echo "新终端: $new_addr"
  sleep 0.1
  return 0
}

# ---------------------------------------------------------------
# 主逻辑
# ---------------------------------------------------------------
ADDR="" ADDR_PID=""
[ -s "$ADDR_FILE" ] && read -r ADDR ADDR_PID <"$ADDR_FILE"

if addr_exists "$ADDR" "$ADDR_PID"; then
  debug_echo "已有终端: $ADDR"
  read -r w h <<<"$(target_size)"
  if window_visible "$ADDR"; then
    hide_terminal "$ADDR"
  else
    show_terminal "$ADDR" "$w" "$h"
  fi
else
  debug_echo "没有现存终端，创建新的"
  if spawn_terminal; then
    read -r ADDR ADDR_PID <"$ADDR_FILE"
    read -r w h <<<"$(target_size)"
    show_terminal "$ADDR" "$w" "$h"
  fi
fi
