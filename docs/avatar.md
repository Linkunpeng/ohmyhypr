# 3D 虚拟形象（Avatar）

桌面右下角的可交互 3D 角色。模型通过 **avatar pack** 配置，换一个形象只需要写一个 `avatar.toml`。

## 交互

| 操作 | 效果 |
|---|---|
| 单击 | 微笑 + 轻跳 + 台词（`lines.click`） |
| 1.5 秒内连点 3 次 | 生气（`lines.poke`） |
| 双击 / `Super+Shift+Y` | 打开对话输入框：本地 LLM 以角色人设流式回答，等待时播放 `thinking` 表情 |
| 拖动 | 移动位置（会被记住，不会拖出显示器） |
| 右键拖动 | 左右旋转角色 |
| 滚轮 | 缩放（放大到窗口装不下为止） |
| 右键单击 | 菜单：聊天 / 换姿势 / 动作（如跳舞）/ 重新加载 / 隐藏 |
| 鼠标悬停 | 身体转向指针 |
| `Super+Y` | 显示 / 隐藏 |

窗口是透明的 layer-shell 浮层，只有角色身体（由骨骼实时投影得到）和气泡会接收点击，其余区域点击会穿透到下面的窗口。

## 命令行

```bash
omh avatar run [--pack ID] [--detach]   # 启动（由 Hyprland autostart 自动执行）
omh avatar say "……"                     # 让她说一句话
omh avatar ask "今天该做什么？"           # 以角色人设回答（本地模型 + GPU 租约）
omh avatar motion dance|next|stop        # 动作 / 下一个待机姿势 / 停止
omh avatar expression smile|angry|sad|surprise|wink|thinking
omh avatar show|hide|toggle|chat|status|quit
omh avatar reload [PACK]                 # 重新加载，或切换到另一个 pack
omh avatar list                          # 列出可用 pack
omh avatar inspect PACK|FILE.pmx         # 列出模型的表情和骨骼，编写 pack 时用
```

## 制作一个 pack

1. 新建 `~/.config/ohmyhypr/avatars/<id>/avatar.toml`（用户目录优先于仓库里的 `avatars/`）。
2. 运行 `omh avatar inspect 模型.pmx`，查看可用的表情（morph）名称。
3. 最少只需要这些字段：

```toml
[avatar]
name = "角色名"
root = "~/3dModel/角色"      # 模型目录；下面的相对路径都相对于它
model = "角色.pmx"
```

常见的 MMD 表情（まばたき / 笑い / あいうえお / 怒り / 困る / びっくり / ウィンク）会**自动识别**，
所以多数模型零配置就能眨眼、说话、做表情。可选字段：

| 段 | 作用 |
|---|---|
| `[camera]` | `target_y`（注视高度）、`distance`、`fov`，用于取景 |
| `[window]` | 浮层窗口的 `width` / `height` |
| `[expressions]` | 语义表情 → morph 名（可以是数组），例如 `thinking = ["EyeGears Turning"]` |
| `[motions]` | `idle` 待机姿势列表（`.vpd` / `.vmd`），`idle_interval` 轮换间隔 |
| `[actions.<name>]` | 命名动作：`file`（`.vmd`）、`loop`；会出现在右键菜单里 |
| `[lines]` | `greet` / `click` / `poke` 台词池 |
| `[persona]` | `prompt`：对话时的人设 system prompt |

示例见 [`avatars/sandrone/avatar.toml`](../avatars/sandrone/avatar.toml)。主题通过 `[avatar] pack = "<id>"` 选择形象。

**版权：** 模型文件绝不提交进仓库（多数 MMD 模型禁止二次配布），pack 只写本地路径。

## 实现

```
host  brain/src/ohmyhypr/avatar/host.py   (系统 python：GTK3 + gtk-layer-shell + WebKit2GTK 4.1)
  ├─ 127.0.0.1 随机端口 HTTP：只服务 avatar/dist 和当前 pack 的目录
  ├─ input region ← 渲染器上报的身体 / 气泡矩形
  ├─ 控制 socket  $XDG_RUNTIME_DIR/ohmyhypr/avatar.sock（NDJSON）
  └─ 监听 theme.json → 切换 pack、显示 / 隐藏、同步气泡配色
renderer  avatar/web/src  (TypeScript + Babylon.js 9 + babylon-mmd 1.3，esbuild 打包)
  ├─ MmdWasmRuntime + 单线程 bullet 物理（file:// 页面拿不到 SharedArrayBuffer，用不了多线程）
  ├─ 动作导演：MmdCompositeAnimation 的 span 交叉淡入淡出（待机姿势 ⇄ 动作）
  ├─ 程序化表现：眨眼、说话口型、表情、转向指针、点击轻跳
  └─ 自动取景：窗口大小固定，每帧按骨骼包围盒平移相机，装不下时拉远（跳舞时不会被裁切）
```

为什么不用 Quickshell 内嵌 WebEngine：Quickshell 0.3 加载 QtWebEngine 时会崩溃
（Chromium 拿不到程序参数）；QtQuick3D 也没有安装，而且不支持 PMX。

## 后续

- 程序化呼吸 / 头部看向光标（骨骼级控制）
- TTS（tts-default）配真实口型同步
- VRM / glTF 格式的 pack
- 支持指定显示器（GTK3 拿不到 connector 名，目前出现在启动时聚焦的显示器上）
