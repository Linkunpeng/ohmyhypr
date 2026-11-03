# 架构

```
┌──────────────────────────────── Human ────────────────────────────────┐
│  keys · voice · mouse · selection                                     │
└───────────────┬───────────────────────────────────────▲───────────────┘
                │ binds (hl.bind)                       │ panels · toasts · bar
┌───────────────▼──────────────┐   global shortcuts   ┌─┴───────────────────────┐
│ Compositor  hypr/  (Lua)     │ ───────────────────▶ │ Shell  shell/ (QML)     │
│ env · look · input · binds   │  ohmyhypr:<name>     │ bar · omnibox · sidebar │
│ rules · ai · autostart       │                      │ screen-ask · approvals  │
│ hl.on(events) ──┐            │ ◀─── hyprctl ─────── │ Omh.dispatch(lua expr)  │
└─────────────────┼────────────┘    dispatch (Lua)    └─────────┬───────────────┘
                  │ events                                      │ omh CLI / socket (M1)
┌─────────────────▼─────────────────────────────────────────────▼───────────────┐
│ Brain  brain/  (Python, `omh` / omhd)                                         │
│  Context Engine ── Model Providers ── Desktop Tools ── Permission + Audit     │
│        │                ├─▶ OpenAI-compatible chat API                        │
│        │                └─▶ Anthropic-compatible messages API                 │
│        └── MCP server (M3) ◀── Claude Code & other agents                     │
└───────────────────────────────────────────────────────────────────────────────┘
```

## 组件

| 组件 | 路径 | 状态 | 职责 |
|---|---|---|---|
| Compositor 配置 | `hypr/hyprland.lua`、`hypr/lua/omh/*.lua` | M0 ✅ | 每个模块负责一个关注点，都返回 `function(s)`；机器相关配置放在 `local.lua` |
| Shell | `shell/` | M0 骨架 | Quickshell UI；通过 `GlobalShortcut { appid: "ohmyhypr" }` 接收 Lua 层的绑定 |
| Brain CLI | `brain/src/ohmyhypr/` | M0 ✅ | `omh doctor` / `omh ctx` / `omh ask` |
| omhd 守护进程 | `brain/` | M1 | 常驻进程：事件订阅、上下文缓存、socket RPC、systemd user service |
| MCP server | `brain/` | M3 | 把 Desktop Tools 暴露给 Agent |
| Theme engine | `brain/src/ohmyhypr/theme.py`、`themes/` | ✅ | theme.toml → theme.json（Shell）+ theme.lua（Hyprland），见 [themes.md](themes.md) |

## 关键约定

### Hyprland Lua dispatch

Hyprland 0.56 使用 Lua 配置时，`hyprctl dispatch` 的参数是 **Lua 表达式**：

```bash
hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'   # ✅
hyprctl dispatch workspace 3                          # ❌ 语法错误
```

Quickshell 自带的 `HyprlandWorkspace.activate()` 等方法发送的是旧语法，**不要用**。
Shell 里统一走 `Omh.dispatch()`，brain 里统一走 `hypr.dispatch()`。

### 入口命名

Lua：`hl.dsp.global("ohmyhypr:<name>")`  ⇄  QML：`GlobalShortcut { appid: "ohmyhypr"; name: "<name>" }`

已保留的名字：`omnibox`、`screen-ask`、`selection`、`sidebar`、`voice-start`、`voice-stop`。

### 路由与隐私

- `[ai] default_provider` 选择配置中的提供商；`--provider` 可指定其他提供商。
- 桌面上下文默认关闭；用 `--context` 或 `ai.include_context = true` 显式启用。
- 上下文用 `<desktop_context>` 包裹，system prompt 里声明它是数据、不是指令。

提供商只依赖 API 格式、URL、模型和可选密钥；显存调度由具体推理服务或其部署环境处理。
在本机共享 GPU 的环境中，使用 LocalAI 前仍须由部署环境确保持有 GPU Keeper 租约。

## 数据流示例：Screen Ask（M2 目标）

```
Super+Shift+S → Lua bind → global ohmyhypr:screen-ask
  → Shell 显示选区遮罩 → slurp/grim 截取 PNG
  → omh ask --image <png> "<用户问题>"
  → 多模态 API（待实现）
  → 流式回答显示在浮层；可"复制 / 发到 Sidebar / 用 Claude 深挖"
```

## 开发与部署

- `make verify`：用 `Hyprland --verify-config` 校验 Lua，并对 brain 做编译检查
- `make dev`：在当前会话里嵌套启动一个 Hyprland，加载本仓库配置，不影响现有桌面
- `make shell`：在当前桌面单独运行 Quickshell（会出现第二个 bar）
- 正式切换（M0 收尾）：`~/.config/hypr/hyprland.lua` 改为 `dofile` 本仓库入口，原文件备份，可一键回滚
