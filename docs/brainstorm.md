# ohmyhypr 头脑风暴：AI Native Desktop

> 2026-10-25 · 初版。这是"想法池"，不是承诺；落地顺序见 [roadmap.md](roadmap.md)。

## 1. 核心命题

传统桌面：**人 → 应用 → 数据**。AI native 桌面：**人 ↔ 意图层 ↔ 应用 / Agent / 模型**。

桌面本身应当是一个 **可感知、可操作、可解释** 的环境：

| 视角 | 桌面对它意味着什么 |
|---|---|
| 人 | 任何时刻、任何位置，一个键 / 一句话 / 一次框选就能唤起智能 |
| Agent | 一个有 API 的环境（MCP）：看得见窗口、读得到剪贴板、能截图、能请求人类确认 |
| 系统 | 配置即代码，AI 能安全地修改桌面自身（diff → verify → reload → 可回滚） |

## 2. 设计原则

1. **本地优先，隐私默认。** 屏幕、剪贴板、语音、窗口标题这类敏感上下文默认只给 LocalAI。云端（Claude）需要显式路由，上下文上云要单独授权。
2. **AI 永不阻塞基础操作。** brain 挂了，桌面照常用；AI 入口一律带超时和降级（GPU 忙 → 提示改用云端或稍后再试）。
3. **Human-in-the-loop。** Agent 的破坏性动作和外发动作，都必须先在 Shell 里确认；所有动作留审计日志。
4. **键盘优先、意图优先。** 一个 Omnibox 胜过十个菜单。
5. **配置即代码。** Lua（合成器）+ QML（界面）+ TOML（brain），全部放进 git。
6. **屏幕内容是不可信数据。** 防 prompt injection：网页、文档里的文字永远不能触发高危工具。
7. **可观测。** 上下文快照、模型调用、Agent 动作都可查看、可回放。

## 3. 智能触点（交互入口）

| 触点 | 触发 | 描述 | 优先级 |
|---|---|---|---|
| Omnibox | `Super+Space` | 应用 / 窗口 / 文件 / 命令 / 自然语言的统一入口；"把浏览器和终端左右平铺"会直接执行 | P0 |
| Screen Ask | `Super+Shift+S` | 框选截图 → VLM：解释、OCR、翻译、转代码、转表格 | P0 |
| Selection Actions | `Super+.` | 对任意选中文本（primary selection）翻译 / 解释 / 润色，结果可回写 | P0 |
| AI Sidebar | `Super+A` | 常驻对话面板，自动携带桌面上下文，可调用桌面工具 | P1 |
| Push-to-talk | 按住 `Super+V` | ASR（SenseVoice）→ 识别为命令，或听写到当前窗口（wtype） | P1 |
| Agent Dock | bar 指示器 | 正在运行的 Claude Code 会话、taskhub 任务；等待审批时高亮 | P1 |
| Approval Toast | 被动 | Claude Code 的 Notification / PermissionRequest hook → Shell 弹窗，可允许 / 拒绝 | P1 |
| Smart Notifications | 被动 | 通知聚合、摘要；专注模式下延迟推送 | P2 |
| Ambient Hints | 被动 | 根据当前上下文给出轻提示（"这个报错要我查一下吗？"），默认关闭 | P2 |

## 4. 能力清单（按层）

### 4.1 感知：Context Engine

- Hyprland 事件流（Lua `hl.on` / socket2）：窗口打开、焦点、标题、工作区
- 焦点应用的语义：终端的 cwd + git 仓库、浏览器的标题 / URL、编辑器当前文件
- 剪贴板历史（cliphist）+ 当前选区
- 按需截图（grim；整屏 / 窗口 / 区域）
- 可选的活动时间线（本地 SQLite，opt-in，一键清除）→ 能回答"我昨天下午在看哪篇论文？"

### 4.2 推理：Model Router

- **本地：** `llm-smart`（文本）、`vlm-default`（截图理解）、`asr-default`、`tts-default`，经 GPU Keeper 租约调用
- **云端：** Claude，负责复杂推理、长任务、代码；通过 `claude` CLI / Agent SDK 调用
- **路由维度：** 隐私级别（含截图 / 剪贴板的默认走本地）、任务类型、延迟预算、用户显式 `--cloud`
- **以后：** embedding 用于剪贴板、文件、历史的语义检索

### 4.3 行动：Desktop Tools

- **窗口：** 聚焦、移动、布局、工作区、启动应用
- **I/O：** 通知、剪贴板读写、向焦点窗口输入文本、截图
- **系统：** 音量、亮度、网络、电源（只读优先）
- **统一暴露两种接口：** Unix socket JSON-RPC（给 Shell）和 MCP Server（给任意 Agent）
- **权限分级：** `read` / `act` / `dangerous`；`dangerous` 每次都要确认

### 4.4 自我配置（Self-configuring Desktop）

- 说一句"把间隙调大一点"或"给 Obsidian 加浮动规则"，流程是：Agent 改 Lua → `Hyprland --verify-config` → 预览 diff → 用户确认 → reload → git commit；任何一步失败都自动回滚
- Lua 自定义布局（`hl.layout.register`）：AI 可以生成新的平铺算法
- 主题：从壁纸取色（matugen / wallust）；ComfyUI 生成壁纸后，全局配色跟着联动

### 4.5 情境工作区（Contexts）

- 说"开始写论文"，就把 Zotero / Obsidian / 浏览器按布局打开到指定工作区；说"收工"则保存会话
- AI 根据窗口内容自动给工作区命名（bar 上显示 `论文 · ohmyhypr · 音乐`）
- 支持会话快照与恢复

## 5. 与本机现有基础设施的结合

| 设施 | 用途 |
|---|---|
| LocalAI `:8080` + GPU Keeper `:6101` | 本地推理主力；与 ComfyUI 共享 16 GB 显存，必须走租约 |
| Claude Code | 重任务 Agent；ohmyhypr MCP 让它能"看见"桌面；它的 hooks 接到 Shell 做通知和审批 |
| knowledgehub / taskhub | Agent Dock 展示任务简报；Sidebar 可以检索知识库 |
| ComfyUI | 生成壁纸 / 主题素材 |

## 6. 技术选型

| 层 | 选择 | 理由 | 备选 |
|---|---|---|---|
| 合成器配置 | Hyprland 0.56 Lua | 原生事件、定时器、自定义布局；`--verify-config` 可做 CI | hyprlang |
| Shell / UI | Quickshell (QML) | 已安装；能写任意面板、浮层和动画；原生 Hyprland IPC 和 GlobalShortcut | AGS/Astal、Waybar+Rofi |
| Brain | Python + uv | AI 生态（anthropic、mcp、OpenAI 兼容接口）、迭代快；负载以 IO 为主 | Go / Rust |
| IPC | Unix socket，NDJSON-RPC | 简单，QML 的 Socket / Process 都能接 | D-Bus |
| Agent 接口 | MCP | Claude Code 等可以直接接入 | 自定义 HTTP |
| 配置 | TOML `~/.config/ohmyhypr/config.toml` | 人类可读，stdlib 能解析 | |

## 7. 风险与开放问题

- **隐私：** 窗口标题里就可能有 ssh 命令、IP 等敏感信息。上下文默认只给本地模型；需要上云时是否逐次授权？
- **延迟：** 本地 LLM 冷启动约 10 秒（实测 11 秒）。是否常驻一个小模型？ComfyUI 占着 GPU 时怎么降级？
- **GPU 竞争：** 和 ComfyUI 共用 16 GB；交互场景下租约 `wait_timeout` 设得很短，宁可快速失败。
- **安全：** Agent "输入文本 / 执行命令"的边界在哪？屏幕上的恶意文字怎么防？
- **迁移：** 现有 JaKooLit 配置怎么平滑切换？先在嵌套会话里开发，稳定后再切，并保留一键回滚。
- **生态稳定性：** Quickshell 0.x 与 Hyprland Lua API 都还在演进；后者的 `hyprctl dispatch` 语法已经变成 Lua 表达式。

## 8. 杠杆排序

1. 骨架 + 干净的基础配置，达到日常可用
2. brain 打通：上下文 + 路由 + `omh ask`
3. Omnibox + Screen Ask + Selection Actions（使用频率最高、价值最大）
4. MCP + Claude Code hooks 审批（让 Agent 成为一等公民）
5. 语音、时间线、自我配置
