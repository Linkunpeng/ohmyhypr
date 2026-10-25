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

	-- P0: unified launcher + natural-language intent
	hl.bind(M .. " + SPACE", shell("omnibox"))
	-- P0: select a region, ask the VLM about it
	hl.bind(M .. " + SHIFT + S", shell("screen-ask"))
	-- P0: act on the current text selection (translate / explain / rewrite)
	hl.bind(M .. " + period", shell("selection"))
	-- P1: persistent chat sidebar with desktop context
	hl.bind(M .. " + A", shell("sidebar"))
	-- P1: push-to-talk (press = start, release = stop)
	hl.bind(M .. " + V", shell("voice-start"))
	hl.bind(M .. " + V", shell("voice-stop"), { release = true })

	-- Theme: picker / instant cycle
	hl.bind(M .. " + SHIFT + T", shell("themes"))
	hl.bind(M .. " + ALT + T", hl.dsp.exec_cmd(s.omh .. " theme next"))
	-- Avatar: show/hide, talk to her
	hl.bind(M .. " + Y", hl.dsp.exec_cmd(s.omh .. " avatar toggle"))
	hl.bind(M .. " + SHIFT + Y", hl.dsp.exec_cmd(s.omh .. " avatar chat"))

	-- Feed desktop events to the brain once omhd exists (M1).
	-- hl.on("window.active", function(w) ... end)
end
