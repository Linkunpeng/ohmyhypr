-- Plain window-manager binds. AI entry points live in omh/ai.lua.

return function(s)
	local M = s.mod

	hl.bind(M .. " + Return", hl.dsp.exec_cmd(s.terminal), { description = "[group:桌面] 启动终端" })
	hl.bind(M .. " + SHIFT + Return", hl.dsp.exec_cmd(string.format("%q %q", s.dropdown_terminal, s.terminal)), { description = "[group:桌面] 显示 / 收起临时终端" })
	hl.bind(M .. " + SHIFT + S", hl.dsp.exec_cmd(string.format("%q", s.screenshot)), { description = "[group:桌面] 截图与标注" })
	hl.bind(M .. " + E", hl.dsp.exec_cmd(s.files), { description = "[group:桌面] 文件管理器" })
	hl.bind(M .. " + B", hl.dsp.exec_cmd(s.browser), { description = "[group:桌面] 浏览器" })
	hl.bind(M .. " + D", hl.dsp.exec_cmd(s.launcher), { description = "[group:桌面] 应用启动器" })
	hl.bind(M .. " + R", hl.dsp.exec_cmd(s.terminal .. " -e ranger"), { description = "[group:桌面] Ranger 文件管理器" })
	hl.bind(M .. " + Q", hl.dsp.window.close(), { description = "[group:窗口] 关闭窗口" })
	hl.bind(M .. " + F", hl.dsp.window.fullscreen(), { description = "[group:窗口] 切换全屏" })
	hl.bind(M .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 1 }), { description = "[group:窗口] 切换最大化" })
	hl.bind(M .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "[group:窗口] 切换窗口浮动" })
	hl.bind(M .. " + P", hl.dsp.window.pseudo(), { description = "[group:窗口] 切换伪平铺" })
	hl.bind("CTRL + ALT + Delete", hl.dsp.exit(), { description = "[group:桌面] 退出 Hyprland" })
	hl.bind("ALT + L", hl.dsp.exec_cmd(string.format("%q lock", s.omh)), { description = "[group:桌面] 锁屏" })

	local dirs = { H = "left", J = "down", K = "up", L = "right", left = "left", down = "down", up = "up", right = "right" }
	for key, dir in pairs(dirs) do
		hl.bind(M .. " + " .. key, hl.dsp.focus({ direction = dir }), { description = "[group:窗口] 聚焦窗口 · " .. dir })
		hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), { description = "[group:窗口] 移动窗口 · " .. dir })
	end

	local step = 50
	hl.bind(M .. " + CTRL + H", hl.dsp.window.resize({ relative = true, x = -step, y = 0 }), { repeating = true, description = "[group:窗口] 调整窗口大小 · 缩小宽度" })
	hl.bind(M .. " + CTRL + L", hl.dsp.window.resize({ relative = true, x = step, y = 0 }), { repeating = true, description = "[group:窗口] 调整窗口大小 · 增加宽度" })
	hl.bind(M .. " + CTRL + K", hl.dsp.window.resize({ relative = true, x = 0, y = -step }), { repeating = true, description = "[group:窗口] 调整窗口大小 · 缩小高度" })
	hl.bind(M .. " + CTRL + J", hl.dsp.window.resize({ relative = true, x = 0, y = step }), { repeating = true, description = "[group:窗口] 调整窗口大小 · 增加高度" })

	-- code:10..19 are the 1..0 keys, independent of keyboard layout.
	for i = 1, 10 do
		local code = "code:" .. (9 + i)
		hl.bind(M .. " + " .. code, hl.dsp.focus({ workspace = i }), { description = "[group:工作区] 切换到工作区 " .. i .. " [key:" .. (i % 10) .. "]" })
		hl.bind(M .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }), { description = "[group:工作区] 移动窗口到工作区 " .. i .. " [key:" .. (i % 10) .. "]" })
		hl.bind(M .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }), { description = "[group:工作区] 发送窗口到工作区 " .. i .. " [key:" .. (i % 10) .. "]" })
	end
	hl.bind(M .. " + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "[group:工作区] 下一个工作区" })
	hl.bind(M .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "[group:工作区] 上一个工作区" })
	hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "[group:工作区] 下一个工作区" })
	hl.bind(M .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "[group:工作区] 上一个工作区" })

	hl.bind(M .. " + U", hl.dsp.workspace.toggle_special(""), { description = "[group:工作区] 显示 / 隐藏特殊工作区" })
	hl.bind(M .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }), { description = "[group:工作区] 移动窗口到特殊工作区" })

	hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "[group:窗口] 拖动窗口" })
	hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "[group:窗口] 鼠标调整窗口大小" })

	hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "[group:媒体] 调高音量" })
	hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true, description = "[group:媒体] 调低音量" })
	hl.bind("xf86audiomute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, description = "[group:媒体] 切换静音" })
	hl.bind("xf86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "[group:媒体] 播放 / 暂停" })
	hl.bind("xf86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "[group:媒体] 下一曲" })
	hl.bind("xf86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "[group:媒体] 上一曲" })
end
