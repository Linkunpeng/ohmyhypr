# 依赖清单与功能链路

本文以仓库默认配置和实际代码为准，记录依赖、用途和缺失时的影响；不代表本机已经安装或服务正在运行。
程序名不一定等于发行版的软件包名。机器覆盖配置、主题 hooks 和用户启动的应用可能引入额外依赖。
组件用途与配置入口另见 [组件表](components.md)。

分类按功能判断：**基础**是运行对应层的前提；**功能依赖**只在使用该功能时需要；
**开发依赖**只在构建或验证时需要；**预留**表示当前没有实际调用链。
这与 `omh doctor` 内部的 required / optional 标记不完全相同，检查范围见文末。

## 基础运行环境

| 依赖 | 用途及限制 | 入口 |
|---|---|---|
| Linux、Wayland、Hyprland 0.56 系列及其 `hyprctl` | 运行 Lua 配置、桌面和 IPC；指标还依赖 Linux `/proc`、`/sys`。其他 Hyprland 版本需自行验证兼容性 | [入口](../hypr/hyprland.lua)、[hypr.py](../brain/src/ohmyhypr/hypr.py) |
| Quickshell（`qs`）、Qt Quick / Wayland 和 Quickshell 提供的 QML 模块 | bar、壁纸、通知、菜单与面板；Qt 需提供 Quick Controls、Layouts 和 Shapes，Quickshell 构建需包含 Hyprland、Wayland、IO、Notifications、PipeWire、MPRIS、SystemTray、DBusMenu 和 Widgets 模块 | [shell.qml](../shell/shell.qml)、[services](../shell/services/) |
| Python 3.12+、`uv`、Bash | `bin/omh` 通过 `uv run` 运行 Brain；脚本使用 Bash。Brain 运行时代码只用 Python 标准库 | [bin/omh](../bin/omh)、[pyproject.toml](../brain/pyproject.toml) |
| D-Bus 会话总线与系统总线、systemd user / logind | 桌面服务、通知、系统托盘、连接管理和会话环境；其中系统总线、logind 按具体功能需要 | [autostart.lua](../hypr/lua/omh/autostart.lua)、[connectivity.py](../brain/src/ohmyhypr/connectivity.py) |
| JetBrainsMono Nerd Font | bar 字符及图标；缺失时字体回退，图标可能显示异常 | [BarStyle.qml](../shell/services/BarStyle.qml) |

## 功能依赖

| 功能 | 依赖 | 缺失或不可用时 | 入口 |
|---|---|---|---|
| 默认应用快捷键 | `kitty`、`thunar`、`chromium`、`rofi`；Ranger 快捷键还需 `ranger` | 对应应用快捷键不可用；终端、文件管理器、浏览器、启动器可在 `local.lua` 替换 | [settings.lua](../hypr/lua/omh/settings.lua)、[binds.lua](../hypr/lua/omh/binds.lua) |
| 临时终端 | 配置的终端、`hyprctl`、`jq` | 临时终端无法创建或切换 | [dropdown-terminal.sh](../scripts/dropdown-terminal.sh) |
| 截图与标注 | `slurp`、`grim`、`satty`、`wl-copy`、`xdg-user-dir` | 选择、截图、编辑、复制或保存流程中相应步骤不可用；脚本使用 `/usr/bin/` 绝对路径，单纯存在于其他 PATH 目录不足以保证可用 | [screenshot.sh](../scripts/screenshot.sh) |
| 锁屏与空闲 | `hyprlock`；自动锁屏另需 `hypridle`、`loginctl` 和 logind | 手动锁屏或自动锁屏对应能力不可用；Hyprlock 还需要系统 PAM 配置。锁屏字体为 Noto Sans CJK SC | [lockscreen.py](../brain/src/ohmyhypr/lockscreen.py) |
| 壁纸取色 | `ffmpeg`，支持读取所选图片格式 | 更换图片并提取配色失败；应用主题时提取失败会回退到主题配色 | [palette.py](../brain/src/ohmyhypr/palette.py)、[theme.py](../brain/src/ohmyhypr/theme.py) |
| 剪贴板与历史 | `wl-paste`；历史记录另需 `cliphist` | 上下文无法读取剪贴板，或历史守护进程无法工作 | [context.py](../brain/src/ohmyhypr/context.py)、[autostart.lua](../hypr/lua/omh/autostart.lua) |
| Wi-Fi 菜单 | 系统 D-Bus、`busctl`、iwd 服务与兼容网卡；需要交互认证时还需 `iwctl` 和终端 | 服务或设备不可用时菜单显示不可用；首次认证依赖终端 | [connectivity.py](../brain/src/ohmyhypr/connectivity.py)、[Connectivity.qml](../shell/services/Connectivity.qml) |
| 蓝牙菜单 | 系统 D-Bus、`busctl`、BlueZ 服务与适配器；扫描/配对需 `bluetoothctl`，交互配对还需终端 | 服务、设备或对应扫描配对功能不可用 | [connectivity.py](../brain/src/ohmyhypr/connectivity.py) |
| 音量与麦克风 | PipeWire、Quickshell PipeWire 模块；`wpctl` / WirePlumber 用于调节，`pavucontrol` 用于右键设置 | 状态或对应控制不可用 | [Audio.qml](../shell/bar/Audio.qml)、[binds.lua](../hypr/lua/omh/binds.lua) |
| 媒体 | MPRIS 兼容播放器和会话 D-Bus；媒体键需 `playerctl`，滚轮调音量需 `wpctl` | 无播放器时无曲目信息；缺少对应命令时媒体键或滚轮无效 | [Media.qml](../shell/bar/Media.qml)、[binds.lua](../hypr/lua/omh/binds.lua) |
| 音频频谱 | `cava`，及其配置使用的 PulseAudio 兼容音频源 | 不显示频谱 | [Cava.qml](../shell/services/Cava.qml)、[cava.conf](../shell/bar/cava.conf) |
| 通知与托盘 | 会话 D-Bus、Quickshell Notifications / SystemTray；主动发送通知需 `notify-send`；托盘恢复需 `busctl` | 缺失时对应通知或托盘功能不可用；嵌套会话不接管通知服务 | [NotificationStore.qml](../shell/services/NotificationStore.qml)、[TrayRecovery.qml](../shell/services/TrayRecovery.qml) |
| 系统指标 | Linux `/proc`、`/sys` 和文件系统统计；GPU 使用率 / 显存读取 AMD 驱动 sysfs，优先选显存最大的设备 | 未提供或不可读的值显示 `—`；不支持的 GPU 驱动不提供此处指标 | [metrics.py](../brain/src/ohmyhypr/metrics.py)、[Gpu.qml](../shell/bar/Gpu.qml) |
| 中文输入与 Qt 外观 | `fcitx5`；`qt6ct` 及其 Qt 平台主题插件 | 输入法或指定的 Qt 外观不可用；主题内容需另行配置 | [autostart.lua](../hypr/lua/omh/autostart.lua)、[env.lua](../hypr/lua/omh/env.lua) |
| AI 问答 | 已配置并可访问的 OpenAI / Anthropic 兼容 HTTP API、模型和按需提供的密钥 | 未配置或服务不可达时问答不可用；默认不附带桌面上下文 | [providers.py](../brain/src/ohmyhypr/providers.py)、[配置示例](../config/ohmyhypr.example.toml) |

连接菜单交互终端使用 `OHMYHYPR_TERMINAL`，未设置时回退到 `kitty`；它与 `local.lua` 的终端设置不是同一个配置入口。
本地 AI 服务的 GPU 租约属于服务部署环境；在本机共享 GPU 时应遵循仓库的 GPU Keeper 要求。

## 构建、验证与预留

| 类别 | 依赖 | 用途 |
|---|---|---|
| 验证 | `make`、Bash、Hyprland、Python 3.12+ | `make verify` 校验 Lua、编译 Python、运行 `unittest` 和解析主题；若 PATH 中有 `ruff` 则额外运行它 |
| 测试可选 | `ffmpeg` | 与实际图片取色有关的测试；没有时对应测试跳过 |
| Python 打包 | `uv`、构建后端 `hatchling` | `bin/omh` 通过 uv 运行项目；首次建立环境能否离线取决于本地 Python 和构建依赖缓存。运行时无第三方 Python 包 |
| 可选开发工具 | `ruff>=0.6`、`pytest>=8` | [pyproject.toml](../brain/pyproject.toml) 的 `dev` 组；`default-groups = []`，默认不安装。`make verify` 使用标准库 `unittest` |
| 预留 | `wtype` | doctor 会检查，但当前没有接入输入操作流程 |

## 主要依赖链路

箭头表示调用或数据流；分支后的工具只在该功能被使用时需要。

```text
Hyprland → hypr/lua/omh/autostart.lua → qs → shell/shell.qml → bar / 面板
                                      └→ bin/omh → uv → Python Brain
bar 系统指标 → SystemStats.qml → bin/omh metrics --watch → /proc、/sys、statvfs
bar 音频 → Quickshell PipeWire → PipeWire；操作 → wpctl → WirePlumber
bar 网络菜单 → bin/omh connectivity → busctl → 系统 D-Bus → iwd / BlueZ
                                              └→ bluetoothctl（扫描）
                                      → 终端 → iwctl / bluetoothctl（交互认证）
截图快捷键 → screenshot.sh → slurp → grim → satty → wl-copy / 截图文件
空闲锁屏 → bin/omh idle → hypridle → loginctl / logind → bin/omh lock → hyprlock / PAM
壁纸和主题 → bin/omh → ffmpeg（图片取色）→ theme.json / theme.lua → Quickshell / Hyprland
AI 问答 → bin/omh ask → 配置的 HTTP API → 模型服务
```

## 检查与维护

- `make doctor` 通过 `bin/omh` 启动，只检查 [doctor.py](../brain/src/ohmyhypr/doctor.py) 中列出的命令是否在 PATH、Hyprland 版本字符串及 AI 配置是否可解析；它不验证服务是否运行、硬件、字体、QML 模块、截图脚本绝对路径或 API 连通性，也不能覆盖本文所有依赖。
- `make verify` 不启动桌面或验证实时服务。`make dev` 会在当前桌面打开嵌套窗口，应先取得用户同意。
- 增删或替换外部调用、服务、QML 模块、字体、构建工具时，同步更新本清单的分类、影响、入口和链路，以及 [组件表](components.md)；需要自动检查的命令同时更新 `doctor.py` 和对应文档。
- `local.lua`、用户主题、主题 hooks、外部模型服务及其自身依赖由使用者按本机情况另行维护，不在仓库默认清单中穷举。
