# 组件表

此表记录项目当前选择的组件、用途和配置入口。它描述仓库配置，不代表本机已安装或服务正在运行；
部署到不同机器时，可用 `make doctor` 检查其覆盖的依赖。替换组件时，同步更新配置、此表和相关文档。

## 核心运行组件

| 用途 | 组件 / 命令 | 接入方式 | 配置或代码入口 |
|---|---|---|---|
| 窗口管理 | Hyprland 0.56+、`hyprctl` | Hyprland 加载 Lua 配置；Shell 和 Brain 通过 `hyprctl` 操作或读取状态 | [hypr/hyprland.lua](../hypr/hyprland.lua)、[hypr.py](../brain/src/ohmyhypr/hypr.py) |
| 桌面界面 | Quickshell（`qs`） | 启动 bar、壁纸、Omnibox、主题面板；Hyprland 启动时执行 | [shell.qml](../shell/shell.qml)、[autostart.lua](../hypr/lua/omh/autostart.lua) |
| 命令行与 AI 接入 | Python 3.12+、`uv`、`bin/omh` | Shell 和 Hyprland 调用 `bin/omh`；Python 运行时使用标准库 | [pyproject.toml](../brain/pyproject.toml)、[bin/omh](../bin/omh) |
| 会话环境 | D-Bus、systemd user | 非嵌套会话启动时同步 Wayland 会话环境变量 | [autostart.lua](../hypr/lua/omh/autostart.lua) |

## 桌面应用与服务

| 用途 | 当前选择 | 接入方式 | 配置入口 |
|---|---|---|---|
| 终端 | Kitty（`kitty`） | `Super+Return` | [settings.lua](../hypr/lua/omh/settings.lua)：`terminal` |
| 终端文件管理器 | Ranger（`ranger`） | `Super+R` 在当前配置的终端中打开 | [binds.lua](../hypr/lua/omh/binds.lua) |
| 临时终端 | 当前终端、`jq` | `Super+Shift+Return` 显示 / 收起；浮窗居中，收起至 `special:scratchpad` | [dropdown-terminal.sh](../scripts/dropdown-terminal.sh)、[settings.lua](../hypr/lua/omh/settings.lua)：`dropdown_terminal` |
| 文件管理器 | Thunar（`thunar`） | `Super+E` | [settings.lua](../hypr/lua/omh/settings.lua)：`files` |
| 浏览器 | Chromium（`chromium`） | `Super+B`；不设置系统默认浏览器 | [settings.lua](../hypr/lua/omh/settings.lua)：`browser` |
| 应用启动器 | Rofi（`rofi -show drun`） | `Super+D`；与 `Super+Space` 的 Omnibox 是两个独立入口 | [settings.lua](../hypr/lua/omh/settings.lua)：`launcher` |
| 通知服务 | Quickshell | 状态栏中间的 Notifications 打开通知历史；新通知在状态栏短暂显示预览 | [NotificationStore.qml](../shell/services/NotificationStore.qml)、[NotificationCenter.qml](../shell/notifications/NotificationCenter.qml) |
| Wi-Fi | iwd、`busctl`、`iwctl` | 状态栏显示连接状态；点击可开关、扫描和连接网络 | [connectivity.py](../brain/src/ohmyhypr/connectivity.py) |
| 蓝牙 | BlueZ、`busctl`、`bluetoothctl` | 状态栏显示连接状态；点击可开关、扫描和管理设备 | [connectivity.py](../brain/src/ohmyhypr/connectivity.py) |
| 发送通知 | `notify-send` | Shell 用它发送通知，由通知服务显示 | [Omh.qml](../shell/services/Omh.qml) |
| 锁屏与空闲管理 | hyprlock、hypridle、`loginctl` | `Alt+L` 锁屏；非嵌套会话按配置空闲或睡眠前锁屏 | [lockscreen.py](../brain/src/ohmyhypr/lockscreen.py)、[配置示例](../config/ohmyhypr.example.toml) |
| 壁纸与取色 | Quickshell、`ffmpeg` | `Super+Shift+W` 选择壁纸；生成的配色同步到 Quickshell 和 Hyprland | [appearance.md](appearance.md)、[palette.py](../brain/src/ohmyhypr/palette.py) |
| 输入法 | Fcitx5（`fcitx5`） | 非嵌套会话启动，设置 `XMODIFIERS` | [autostart.lua](../hypr/lua/omh/autostart.lua)、[env.lua](../hypr/lua/omh/env.lua) |
| 剪贴板 | wl-clipboard（`wl-paste`）、cliphist | Brain 可读取文本；非嵌套会话监听文本和图片并存入历史 | [context.py](../brain/src/ohmyhypr/context.py)、[autostart.lua](../hypr/lua/omh/autostart.lua) |
| 音量 | WirePlumber（`wpctl`）及音频服务 | 音量键调用默认音频输出 | [binds.lua](../hypr/lua/omh/binds.lua) |
| 媒体播放 | playerctl | 媒体键控制播放、上一首和下一首 | [binds.lua](../hypr/lua/omh/binds.lua) |
| Qt 主题 | qt6ct | 设置 `QT_QPA_PLATFORMTHEME`，具体主题需在外部配置 | [env.lua](../hypr/lua/omh/env.lua) |

通知中心使用 `notifications` IPC 目标；例如
在仓库目录运行 `qs ipc -p "$PWD/shell" call notifications closeCenter` 可收起通知浮窗。
通知历史最多保留 50 条，存于内存中，Shell 重载或退出后可能清空；嵌套开发会话不会接管系统通知。

终端、文件管理器、浏览器和启动器可通过 gitignored 的 `hypr/lua/omh/local.lua` 覆盖；
模板见 [local.example.lua](../hypr/lua/omh/local.example.lua)。空闲锁屏策略由 `config.toml` 的 `[lock]` 配置；其余服务目前在对应模块中直接指定。
`make dev` 是嵌套会话，会跳过表中的会话级守护进程自启动。

## 可选接口与规划组件

| 用途 | 组件 / 接口 | 状态与配置 |
|---|---|---|
| AI 模型 | OpenAI 或 Anthropic 兼容 HTTP API | 已接入；通过用户配置提供 URL、模型和可选密钥，本地与远端使用相同接口。见 [配置示例](../config/ohmyhypr.example.toml) |
| 截图与标注 | `slurp`、`grim`、`satty`、`wl-copy`、`xdg-user-dir` | `Super+Shift+S` 框选后进入 Satty；Enter 复制，支持标注和保存到 Pictures/Screenshots。见 [screenshot.sh](../scripts/screenshot.sh)；AI Screen Ask 仍待实现 |
| 模拟输入 | `wtype` | `doctor` 可检查；作为未来输入能力的候选，当前未接入实际操作流程 |

## 检查与维护

- `make doctor` 当前检查 `Hyprland`、`hyprctl`、`qs`、`wl-paste`、`grim`、`slurp`、`satty`、`wl-copy`、`xdg-user-dir`、`cliphist`、`wtype`、`notify-send`、`ffmpeg`、`hyprlock`、`hypridle`、`loginctl`、`busctl`、`iwctl` 和 `bluetoothctl`，并检查 AI 提供商配置。它不检查表中的所有应用、服务状态或 API 连通性。
- `make verify` 校验 Hyprland 配置、Python、接口测试和主题；它不启动桌面，也不验证通知、音频等服务是否运行。
- 添加或替换组件时，记录用途、实际调用方式、配置位置以及是否已实现；需要自动检查的依赖应同时更新 [doctor.py](../brain/src/ohmyhypr/doctor.py)。

状态栏右侧使用 Quickshell SystemTray/DBusMenu 显示后台应用。系统指标通过
[metrics.py](../brain/src/ohmyhypr/metrics.py) 读取 `/proc`、CPU hwmon 和 `wpctl`，每 2 秒刷新。
