# ohmyhypr

> An AI native Hyprland desktop — 把智能做进桌面本身，而不是多开一个聊天窗口。

ohmyhypr 是一套从零开始的 Hyprland 配置，包含以下部分：

| 层 | 目录 | 技术 | 作用 |
|---|---|---|---|
| Compositor | `hypr/` | Hyprland 0.56 **Lua** 配置 | 窗口管理、绑定、事件钩子 |
| Shell | `shell/` | Quickshell (QML) | bar、Omnibox、AI 面板、审批弹窗 |
| Brain | `brain/` | Python (uv) · `omh` | 桌面上下文、兼容 API 模型接入、桌面工具 / MCP |
| Themes | `themes/` | TOML → `omh theme apply` | 一键切换壁纸 / 配色 / 形状 / bar |

设计原则：**隐私优先**（桌面上下文默认不发送）、**AI 不阻塞基础操作**、
**Human-in-the-loop**、**配置即代码**。完整想法见 [docs/brainstorm.md](docs/brainstorm.md)。

## 快速开始

```bash
make doctor        # 检查依赖与 AI 配置
make verify        # Hyprland --verify-config、Python、接口与主题检查
make dev           # 嵌套 Hyprland 窗口里试用，不影响当前桌面
bin/omh wallpaper set ~/Pictures/wallpaper.jpg  # 更换壁纸并生成配色
bin/omh lock       # 手动锁屏

bin/omh theme apply moonlantern     # 一键换主题（bin/omh 直接从仓库运行，无需安装）
omh ctx            # 当前桌面上下文（JSON）
omh ask "这段报错什么意思"          # 默认提供商，不附带桌面上下文
omh ask --provider anthropic "帮我设计一个方案"
omh ask --context "看看我的桌面"     # 显式附带桌面上下文（含剪贴板）
```

机器相关设置（显示器、显卡环境变量）：复制 `hypr/lua/omh/local.example.lua` 到 `local.lua`。
AI 配置：复制 [config/ohmyhypr.example.toml](config/ohmyhypr.example.toml) 到
`~/.config/ohmyhypr/config.toml`，为提供商填写兼容协议类型、API base URL 和模型 ID，
并按需填写 `api_key` 或 `api_key_env`（环境变量名）。同一文件可配置多个提供商；
`[ai] default_provider` 控制 Omnibox 使用的默认项，也可通过 `--provider` 指定。
自建服务同样使用其兼容 API 地址，不依赖特定模型服务或 Claude CLI。
使用 `api_key_env` 时，环境变量必须在启动桌面 shell 的会话中可用。

桌面上下文默认关闭；`--context` 或 `[ai] include_context = true` 会启用，
`--no-context` 可对单次提问关闭。
旧版 `[local]`、`[cloud]`、`[router]` 配置及
`--local` / `--cloud` 选项已由新的提供商配置和 `--provider` 取代。
本项目不再管理推理服务的 GPU 租约；在本机共享 GPU 的环境中，使用 LocalAI 前需由
服务部署环境确保 GPU Keeper 租约已持有。

## 快捷键

| 键 | 动作 | 状态 |
|---|---|---|
| `Alt+K` | 全部快捷键速查表 | ✅ |
| `Alt+B` | 显示 / 隐藏状态栏 | ✅ |
| `Super+Space` | Omnibox：问任何事 / 让桌面做事 | 雏形 |
| `Super+Shift+S` | 框选截图 → Satty 标注 / 复制 / 保存 | ✅ |
| `Super+.` | 对选中文本：翻译 / 解释 / 润色 | 规划中 |
| `Super+A` | AI Sidebar | 规划中 |
| 按住 `Super+V` | 语音 push-to-talk | 规划中 |
| `Super+Shift+T` / `Super+Alt+T` | 主题面板 / 切到下一个主题 | ✅ |
| `Super+Shift+W` / `Alt+L` | 选择壁纸 / 锁屏 | ✅ |
| `Super+Return` / `Q` / `F` / `T` | 终端 / 关闭 / 全屏 / 浮动 | ✅ |
| `Super+R` | 在终端中打开 Ranger | ✅ |
| `Super+Shift+Return` | 显示 / 收起临时终端，保留终端会话 | ✅ |
| `Super+HJKL`（+`Shift` / `Ctrl`） | 聚焦（移动 / 调整大小） | ✅ |
| `Super+1..0`（+`Shift`） | 切换工作区（移动窗口到工作区） | ✅ |

速查表从 Hyprland 当前已注册的绑定读取按键和 `description`。修改快捷键时在对应的
`hypr/lua/omh/binds.lua` 或 `ai.lua` 中维护说明；说明开头用 `[group:分类名]` 指定分类，
没有分类的本机自定义绑定会列在「其他」中。
对 `code:` 形式的物理按键，由于当前 Hyprland 输出不包含键码，说明中用 `[key:…]` 提供显示名称。

## 文档

- [组件表](docs/components.md)：依赖、用途、启动方式与配置入口
- [依赖清单与功能链路](docs/dependencies.md)：按基础、功能和开发分类，说明缺失影响及调用关系
- [头脑风暴](docs/brainstorm.md)：愿景、触点、能力、选型、风险
- [架构](docs/architecture.md)：分层、约定、数据流
- [Roadmap](docs/roadmap.md)：M0–M5
- [主题](docs/themes.md)：字段说明、切换流程
- [壁纸、配色与锁屏](docs/appearance.md)：更换壁纸、独立配色和空闲锁屏

正式启用（接管 `~/.config/hypr`，自动备份，可回滚）：`scripts/switch.sh enable`，撤销用 `scripts/switch.sh disable`。

## License

MIT
