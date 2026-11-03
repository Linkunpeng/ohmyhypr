# 主题

一个 `theme.toml` 定义默认壁纸、配色、窗口边框、控件形状、状态栏样式、字体和特效。壁纸和配色也可独立管理，见 [壁纸、配色与锁屏](appearance.md)。

```bash
omh theme list            # * 标出当前主题
omh theme apply moonlantern  # 一键切换
omh theme next            # 切到下一个（Super+Alt+T）
```

`Super+Shift+T` 打开主题选择面板（← → 选择，Enter 应用）。

## 切换时发生了什么

```
omh theme apply <id>
  ├─ 解析 theme.toml，与默认值合并
  ├─ 默认壁纸存在时提取配色，否则使用主题配色
  ├─ 写 $XDG_STATE_HOME/ohmyhypr/palette.json ──▶ 供其他工具和 hooks 读取
  ├─ 写 $XDG_STATE_HOME/ohmyhypr/theme.json ──▶ Quickshell（颜色渐变过渡、壁纸交叉淡化、bar 形状）
  ├─ 写 $XDG_STATE_HOME/ohmyhypr/theme.lua  ──▶ hyprctl reload config-only（边框、圆角、间隙、模糊、阴影、动画）
  │     （只在 ohmyhypr 会话里 reload，通过 `hyprctl repl 'return OHMYHYPR_ROOT'` 判断）
  └─ 依次运行 [hooks].apply（环境变量 OHMYHYPR_THEME_JSON / OHMYHYPR_PALETTE_JSON 指向状态文件）
```

## 字段

主题放在 `themes/<id>/theme.toml`（仓库内置），或 `~/.config/ohmyhypr/themes/<id>/theme.toml`（用户自定义，同名时优先）。所有字段都可省略。

| 段 | 字段 |
|---|---|
| `[meta]` | `name`、`description`、`dark` |
| `[wallpaper]` | `path`（`~` 或相对路径均可；缺失时用配色渐变）、`fit` = `cover` \| `contain` \| `center` |
| `[palette]` | `bg` `surface` `fg` `muted` `accent` `accent_alt` `urgent` `border_active` `border_inactive`（`#rrggbb[aa]`，也可以写其他键名作引用，如 `"accent"`）、`opacity`（面板不透明度）、`bar_opacity`（可选，状态栏不透明度） |
| `[shape]` | `radius`（窗口和面板圆角）、`border`、`gaps_in`、`gaps_out`、`bar` = `floating` \| `docked`、`bar_position` = `top` \| `bottom`、`bar_height`、`widget` = `pill` \| `rounded` \| `square` |
| `[font]` | `ui`、`mono`、`size` |
| `[effects]` | `blur`、`shadow`、`dim_inactive`、`animation` = `smooth` \| `snappy` \| `none` |
| `[hooks]` | `apply = ["shell 命令", …]`，用来同步 kitty、GTK 等外部程序 |

壁纸取色会根据图像亮度和文字颜色自动计算 `bar_opacity`：浅色背景下提高不透明度，
深色背景下保留更多透明感。手动应用包含该字段的配色文件时使用文件中的值。

内置主题：

| 主题 | 风格 |
|---|---|
| `moonlantern` | 月灯（默认）：墨绿青灰、方正控件、贴边 bar |
| `sandrone` | 木偶：黄铜与绯红、直角控件、贴边 bar |
| `midnight` | 冷色玻璃、悬浮胶囊 bar |
| `porcelain` | 浅色、底部 bar |


状态栏使用左、中、右三段独立悬浮布局，段间透明区域可点击下方窗口。
位置由 `[shape] bar_position` 控制；`bar` 为旧主题兼容字段，现有主题统一使用三段布局。
