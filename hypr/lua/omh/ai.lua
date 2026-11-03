-- AI entry points ("intelligence touchpoints").
--
-- UI surfaces are Quickshell GlobalShortcuts under the `ohmyhypr` app id
-- (see shell/), triggered here via hl.dsp.global("ohmyhypr:<name>").
-- Headless actions call the `omh` CLI directly.

return function(s)
	local M = s.mod

	local function shell(name)
		return hl.dsp.global("ohmyhypr:" .. name)
	end

	hl.bind("ALT + K", shell("shortcuts"), { description = "[group:桌面] 快捷键速查表" })
	hl.bind("ALT + B", shell("toggle-bar"), { description = "[group:桌面] 显示 / 隐藏状态栏" })

	-- P0: unified launcher + natural-language intent
	hl.bind(M .. " + SPACE", shell("omnibox"), { description = "[group:AI] AI 问答与启动器" })
	-- P0: act on the current text selection (translate / explain / rewrite)
	hl.bind(M .. " + period", shell("selection"), { description = "[group:AI] 处理选中文本（规划中）" })
	-- P1: persistent chat sidebar with desktop context
	hl.bind(M .. " + A", shell("sidebar"), { description = "[group:AI] AI 侧边栏（规划中）" })
	-- P1: push-to-talk (press = start, release = stop)
	hl.bind(M .. " + V", shell("voice-start"), { description = "[group:AI] 语音输入（规划中）" })
	hl.bind(M .. " + V", shell("voice-stop"), { release = true, description = "[group:AI] 结束语音输入（规划中）" })

	-- Wallpaper picker
	hl.bind(M .. " + SHIFT + W", shell("wallpaper"), { description = "[group:桌面] 选择壁纸" })

	-- Theme: picker / instant cycle
	hl.bind(M .. " + SHIFT + T", shell("themes"), { description = "[group:桌面] 选择主题" })
	hl.bind(M .. " + ALT + T", hl.dsp.exec_cmd(s.omh .. " theme next"), { description = "[group:桌面] 切换下一个主题" })

	-- Avatar: show/hide, talk to her
	hl.bind(M .. " + Y", hl.dsp.exec_cmd(s.omh .. " avatar toggle"))
	hl.bind(M .. " + SHIFT + Y", hl.dsp.exec_cmd(s.omh .. " avatar chat"))

	-- Feed desktop events to the brain once omhd exists (M1).
	-- hl.on("window.active", function(w) ... end)
end
