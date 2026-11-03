# 形象适配接口

ohmyhypr 不包含模型、渲染器或动作实现。独立的形象程序通过本机 Unix socket
实现以下接口，主项目通过 `[avatar]` 配置连接。参考实现是相邻仓库 `ohmyavatar`。

## 配置和使用

在 `~/.config/ohmyhypr/config.toml` 中配置适配器启动命令：

```toml
[avatar]
command = ["/home/your-user/workspace/ohmyavatar/bin/ohmyavatar"]
model = "sandrone" # 可选；适配器内部的模型 ID
# socket = "/run/user/1000/ohmyavatar/avatar.sock" # 可选
```

默认 socket 为 `$XDG_RUNTIME_DIR/ohmyavatar/avatar.sock`；没有该变量时为
`/tmp/ohmyavatar-<uid>/ohmyavatar/avatar.sock`。适配器会在登录时按配置启动，
也可运行 `bin/omh avatar run --detach`；空 `command` 表示未配置。

```bash
bin/omh avatar status
bin/omh avatar load sandrone    # 模型 ID 由适配器定义
bin/omh avatar unload
bin/omh avatar persona          # 当前模型的人物设定
bin/omh avatar motion idle_1
bin/omh avatar motion notify_1
bin/omh avatar say "你好"
bin/omh avatar ask "今天做什么？"
bin/omh avatar show             # hide / toggle / chat / quit
```

动作槽位固定为 `idle_1`、`idle_2`、`idle_3`、`notify_1`、`notify_2`、`notify_3`。
均为可选，缺失时命令成功但不会触发动作；`status` 中的 `actions` 列出当前可用动作。
模型是异步加载的：`load` 只确认请求已接受，`status.state` 变为 `loaded` 才表示加载完成；
`failed` 表示加载失败，`unloading` 表示正在卸载，`empty` 表示没有模型。
形象主题和模型配置归适配器管理，不随 ohmyhypr 主题切换。

`ask` 在 ohmyhypr 读取适配器返回的人设并调用已配置的 AI 提供商；桌面上下文仍遵循
`ai.include_context`。适配器的聊天输入可通过启动时传入的 `AVATAR_CHAT_COMMAND`
转发给 ohmyhypr，因此渲染进程不需要知道 AI 的配置。

## 协议 v1

每个连接可发送一行 UTF-8 JSON，服务端返回一行 JSON。所有响应包含布尔 `ok`；
错误响应包含 `error`。客户端应处理 socket 不存在、超时和错误响应，不依赖某种渲染技术。
主项目启动适配器时传递 `AVATAR_SOCKET`、可选 `AVATAR_MODEL`，以及
`AVATAR_CHAT_COMMAND`（JSON 字符串数组；聊天内容作为最后一个参数传入）。

| 请求 | 成功响应 / 行为 |
|---|---|
| `{"cmd":"status"}` | `version: 1`、`state`、`model`、`actions`；`ready` 表示渲染器已就绪 |
| `{"cmd":"load","model":"id"}` | 接受模型加载请求，之后通过 `status` 查询状态 |
| `{"cmd":"unload"}` | 接受模型卸载请求；通过 `status.state` 确认进入 `empty` |
| `{"cmd":"persona"}` | `persona` 字符串；无模型或无人设时为空 |
| `{"cmd":"motion","name":"idle_1"}` | `supported: true/false`；不存在的标准动作不报错 |
| `{"cmd":"show"}` / `hide` / `toggle` / `quit` | 管理适配器窗口与进程 |
| `{"cmd":"say","text":"..."}` / `chat` | 显示文本 / 打开输入框 |
| `{"cmd":"thinking","on":true}` / `{"cmd":"stream","chunk":"..."}` / `stream_end` | 可选对话显示能力 |

模型正在加载或卸载时，`load` 和 `unload` 返回错误，避免并发切换导致状态不一致。
协议本身不规定模型格式、资源路径、动作文件或渲染方式。
