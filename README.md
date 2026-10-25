# ohmyhypr

> An AI native Hyprland desktop — 把智能做进桌面本身，而不是多开一个聊天窗口。

ohmyhypr 是一套从零开始的 Hyprland 配置，分三层：

| 层 | 目录 | 技术 | 作用 |
|---|---|---|---|
| Compositor | `hypr/` | Hyprland 0.56 **Lua** 配置 | 窗口管理、绑定、事件钩子 |
| Shell | `shell/` | Quickshell (QML) | bar、Omnibox、AI 面板、审批弹窗 |
| Brain | `brain/` | Python (uv) · `omh` | 桌面上下文、模型路由（LocalAI ⇄ Claude）、桌面工具 / MCP |
| Avatar | `avatar/` + `avatars/` | Babylon.js + babylon-mmd · GTK/WebKit 浮层 | 可交互 3D 形象，pack 可任意替换 |
| Themes | `themes/` | TOML → `omh theme apply` | 一键切换壁纸 / 配色 / 形状 / bar / 形象 |

设计原则：**本地优先**（隐私数据默认只给本地模型）、**AI 不阻塞基础操作**、
**Human-in-the-loop**、**配置即代码**。完整想法见 [docs/brainstorm.md](docs/brainstorm.md)。

## 快速开始

```bash
make doctor        # 检查依赖与本地 AI 服务
make avatar        # 构建 3D 形象渲染器（npm）
make verify        # Hyprland --verify-config、Python、主题、pack、TypeScript 检查
make dev           # 嵌套 Hyprland 窗口里试用，不影响当前桌面
make avatar-run    # 在当前桌面直接召唤形象

bin/omh theme apply sandrone        # 一键换主题（bin/omh 直接从仓库运行，无需安装）
omh avatar ask "今天该做什么？"       # 和形象对话（本地模型，角色人设）
omh ctx            # 当前桌面上下文（JSON）
omh ask "这段报错什么意思"          # 本地 LocalAI，附带桌面上下文
omh ask --cloud "帮我设计一个方案"   # Claude，默认不附带上下文
```

机器相关设置（显示器、显卡环境变量）：复制 `hypr/lua/omh/local.example.lua` 到 `local.lua`。
brain 配置：复制 `config/ohmyhypr.example.toml` 到 `~/.config/ohmyhypr/config.toml`。

## 快捷键

| 键 | 动作 | 状态 |
|---|---|---|
| `Super+Space` | Omnibox：问任何事 / 让桌面做事 | 雏形 |
| `Super+Shift+S` | Screen Ask：框选屏幕提问 | 规划中 |
| `Super+.` | 对选中文本：翻译 / 解释 / 润色 | 规划中 |
| `Super+A` | AI Sidebar | 规划中 |
| 按住 `Super+V` | 语音 push-to-talk | 规划中 |
| `Super+Shift+T` / `Super+Alt+T` | 主题面板 / 切到下一个主题 | ✅ |
| `Super+Y` / `Super+Shift+Y` | 显示或隐藏形象 / 和她对话 | ✅ |
| `Super+Return` / `Q` / `F` / `T` | 终端 / 关闭 / 全屏 / 浮动 | ✅ |
| `Super+HJKL`（+`Shift` / `Alt` / `Ctrl`） | 聚焦（移动 / 交换 / 调整大小） | ✅ |
| `Super+1..0`（+`Shift`） | 切换工作区（移动窗口到工作区） | ✅ |

## 文档

- [头脑风暴](docs/brainstorm.md)：愿景、触点、能力、选型、风险
- [架构](docs/architecture.md)：分层、约定、数据流
- [Roadmap](docs/roadmap.md)：M0–M5
- [3D 形象](docs/avatar.md)：交互、命令、如何制作 pack
- [主题](docs/themes.md)：字段说明、切换流程

正式启用（接管 `~/.config/hypr`，自动备份，可回滚）：`scripts/switch.sh enable`，撤销用 `scripts/switch.sh disable`。

## License

MIT
