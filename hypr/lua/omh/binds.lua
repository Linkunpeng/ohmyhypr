-- Plain window-manager binds. AI entry points live in omh/ai.lua.

return function(s)
	local M = s.mod

	hl.bind(M .. " + Return", hl.dsp.exec_cmd(s.terminal))
	hl.bind(M .. " + E", hl.dsp.exec_cmd(s.files))
	hl.bind(M .. " + B", hl.dsp.exec_cmd(s.browser))
	hl.bind(M .. " + D", hl.dsp.exec_cmd(s.launcher))
	hl.bind(M .. " + Q", hl.dsp.window.close())
	hl.bind(M .. " + F", hl.dsp.window.fullscreen())
	hl.bind(M .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 1 }))
	hl.bind(M .. " + T", hl.dsp.window.float({ action = "toggle" }))
	hl.bind(M .. " + P", hl.dsp.window.pseudo())
	hl.bind("CTRL + ALT + Delete", hl.dsp.exit())

	local dirs = { H = "left", J = "down", K = "up", L = "right", left = "left", down = "down", up = "up", right = "right" }
	for key, dir in pairs(dirs) do
		hl.bind(M .. " + " .. key, hl.dsp.focus({ direction = dir }))
		hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
		hl.bind(M .. " + ALT + " .. key, hl.dsp.window.swap({ direction = dir }))
	end

	local step = 50
	hl.bind(M .. " + CTRL + H", hl.dsp.window.resize({ relative = true, x = -step, y = 0 }), { repeating = true })
	hl.bind(M .. " + CTRL + L", hl.dsp.window.resize({ relative = true, x = step, y = 0 }), { repeating = true })
	hl.bind(M .. " + CTRL + K", hl.dsp.window.resize({ relative = true, x = 0, y = -step }), { repeating = true })
	hl.bind(M .. " + CTRL + J", hl.dsp.window.resize({ relative = true, x = 0, y = step }), { repeating = true })

	-- code:10..19 are the 1..0 keys, independent of keyboard layout.
	for i = 1, 10 do
		local code = "code:" .. (9 + i)
		hl.bind(M .. " + " .. code, hl.dsp.focus({ workspace = i }))
		hl.bind(M .. " + SHIFT + " .. code, hl.dsp.window.move({ workspace = i }))
		hl.bind(M .. " + CTRL + " .. code, hl.dsp.window.move({ workspace = i, follow = false }))
	end
	hl.bind(M .. " + Tab", hl.dsp.focus({ workspace = "m+1" }))
	hl.bind(M .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))
	hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
	hl.bind(M .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

	hl.bind(M .. " + U", hl.dsp.workspace.toggle_special(""))
	hl.bind(M .. " + SHIFT + U", hl.dsp.window.move({ workspace = "special" }))

	hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
	hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

	hl.bind("xf86audioraisevolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
	hl.bind("xf86audiolowervolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
	hl.bind("xf86audiomute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
	hl.bind("xf86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
	hl.bind("xf86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
	hl.bind("xf86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
end
