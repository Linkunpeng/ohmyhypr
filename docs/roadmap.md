# Roadmap

## M0 · Foundation
- [x] 仓库骨架、头脑风暴、架构文档
- [x] Hyprland Lua 模块化基础配置，通过 `--verify-config`
- [x] Quickshell 骨架：bar（工作区 / 时钟 / Ask 按钮）、Omnibox 雏形
- [x] `omh doctor` / `omh ctx` / `omh ask`（OpenAI / Anthropic 兼容 API）
- [ ] 在嵌套会话 `make dev` 中完成日常可用性验证（截图、锁屏、媒体键）
- [x] 主题系统：`theme.toml` → 壁纸、配色、形状、bar、字体、特效一键切换；主题面板
- [x] 3D 形象：通过接口接入独立适配器，读取人物设定及触发可选动作
- [x] 切换脚本 `scripts/switch.sh`：接管 `~/.config/hypr`，带备份和回滚
- [x] 壁纸自动取色并同步 Hyprland、Quickshell 和锁屏
- [ ] kitty / GTK 的主题 hooks 模板

## M1 · Brain
- [ ] `omhd` 常驻进程 + systemd user unit
- [ ] Unix socket NDJSON-RPC；Shell 改用 socket（替代逐次 spawn CLI）
- [ ] 订阅 Hyprland 事件，维护上下文缓存（含终端 cwd / git 仓库）
- [ ] 路由策略可配置；本地不可用时的降级提示
- [ ] 审计日志 `~/.local/state/ohmyhypr/audit.jsonl`

## M2 · Interaction（P0 触点）
- [ ] Omnibox：应用 / 窗口 / 命令检索 + 自然语言意图 → 执行 Desktop Tools（先预览，后执行）
- [ ] Screen Ask：选区截图 → VLM，结果浮层
- [ ] Selection Actions：翻译 / 解释 / 润色 / 回写

## M3 · Agents
- [ ] ohmyhypr MCP server（窗口、剪贴板、截图、通知、ask_user 确认）
- [ ] Claude Code hooks → Shell 审批 toast
- [ ] Agent Dock：运行中的会话 + taskhub 简报
- [ ] AI Sidebar

## M4 · Voice & Memory
- [ ] Push-to-talk：ASR → 命令 / 听写；TTS 朗读，形象做口型同步
- [ ] 活动时间线（opt-in、本地）+ 语义检索
- [ ] 剪贴板语义搜索

## Avatar 后续
- [ ] 骨骼级呼吸 / 头部看向光标
- [ ] VRM / glTF pack
- [ ] 形象对 Agent 事件做出反应（任务完成、等待审批）
- [ ] 指定显示器

## M5 · Self-configuring
- [ ] 自然语言改配置：diff → verify → 确认 → reload → commit / 回滚
- [ ] 情境工作区 & 会话恢复、AI 工作区命名
- [ ] AI 生成的 Lua 布局、ComfyUI 壁纸联动主题
