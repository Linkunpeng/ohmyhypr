# 壁纸、配色与锁屏

## 更换壁纸

按 `Super+Shift+W` 打开缩略图浮窗，默认递归列出
`~/Pictures/wallpapers` 中的图片。单击选择后按 Enter 或点击「应用到此屏幕」，也可双击应用；
Esc 关闭。目标屏幕在打开浮窗时固定，应用时仅更换这块屏幕的壁纸。

在 `~/.config/ohmyhypr/config.toml` 中更换目录：

```toml
[wallpaper]
directory = "~/Pictures/wallpapers"
```

命令行也可指定目标屏幕（不指定 `--screen` 时应用到全部屏幕）：

```bash
bin/omh wallpaper set ~/Pictures/wallpaper.jpg
bin/omh wallpaper set ~/Pictures/wallpaper.png --fit contain  # cover / contain / center
bin/omh wallpaper set ~/Pictures/wallpaper.jpg --screen HDMI-A-3
bin/omh wallpaper list  # JSON 缩略图目录清单
bin/omh wallpaper current
bin/omh wallpaper reset  # 恢复当前主题的默认壁纸和配色
```

更换壁纸时，使用 `ffmpeg` 缩小并读取图像的可见像素，生成深色或浅色配色（由当前主题决定）。
壁纸可按屏幕独立保存，文字、强调色和边框等界面配色则全局更新；主题的圆角、间距、字体和特效保持不变。
Quickshell 监听状态文件更新壁纸和控件颜色；在 ohmyhypr 会话内，Hyprland 配置会重新加载以更新边框。
取色失败时，壁纸和已有配色均不会更改。主题默认壁纸不存在或取色失败时，则保留主题原有颜色。

`omh theme apply <id>` 会切换到该主题自己的默认壁纸；若默认壁纸存在则取色，否则使用主题配色。

## 独立管理配色

```bash
bin/omh palette current
bin/omh palette extract ~/Pictures/wallpaper.jpg > /tmp/my-palette.json
bin/omh palette extract ~/Pictures/wallpaper.jpg --light > /tmp/my-light-palette.json
bin/omh palette apply /tmp/my-palette.json
```

`extract` 只预览，不修改桌面；`apply` 单独应用 JSON 配色，不改变壁纸和窗口布局。
JSON 需要 `bg`、`surface`、`fg`、`muted`、`accent`、`accent_alt`、`urgent`、
`border_active`、`border_inactive`，均为 `#rrggbb`；`opacity` 可选，为 0 到 1。
系统也接受 `palette current` 返回的完整 JSON。重新设置壁纸会再次从图片生成配色。

配色处理位于 [palette.py](../brain/src/ohmyhypr/palette.py)，当前配色独立保存为
`$XDG_STATE_HOME/ohmyhypr/palette.json`，并同步到 Shell 使用的 `theme.json` 和 Hyprland 使用的
`theme.lua`（未设置 XDG 变量时使用 `~/.local/state`）。主题 hooks 也可通过
`OHMYHYPR_PALETTE_JSON` 环境变量读取当前配色。

## 锁屏

- `Alt+L` 或 `bin/omh lock` 使用 Hyprlock 锁屏。
- 正常会话中的 hypridle 默认在空闲 600 秒后请求锁屏，并在系统睡眠前请求锁屏；嵌套开发会话不会启动 hypridle。
- 锁屏使用当前桌面的模糊截图作为背景，与原有锁屏样式一致。解锁使用系统的 Hyprlock/PAM 配置。

在 `~/.config/ohmyhypr/config.toml` 中调整：

```toml
[lock]
timeout_seconds = 600  # 0 表示不因空闲自动锁屏
before_sleep = true    # 睡眠前锁屏；false 关闭此项
```

依赖 `hyprlock`、`hypridle` 和 `loginctl`。配置在 hypridle 启动时读取；修改空闲策略后，
需在合适的时机重新启动 hypridle 或重新登录。项目生成的锁屏与空闲配置
保存在 `$XDG_STATE_HOME/ohmyhypr/`，不修改 `~/.config/hypr`。

## 状态栏

右侧显示 CPU 占用率、CPU 温度、内存占用百分比、当前输出音量和系统托盘。
指标每 2 秒刷新，温度按 CPU 传感器名称识别；读取不到时显示「—」。静音时仍显示已设置的音量百分比。
托盘支持左键激活、右键菜单、中键和滚轮；只有支持系统托盘协议的应用才会显示。
主题、壁纸、锁屏和 Ask 通过快捷键打开，栏上不再提供功能按钮。
