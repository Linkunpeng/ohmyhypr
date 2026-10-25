return function(s)
	local p = s.palette

	hl.config({
		general = {
			border_size = 2,
			gaps_in = 5,
			gaps_out = 10,
			resize_on_border = true,
			layout = "dwindle",
			col = {
				active_border = p.accent,
				inactive_border = p.inactive,
			},
		},

		dwindle = {
			preserve_split = true,
		},

		decoration = {
			rounding = 12,
			dim_inactive = false,
			shadow = {
				enabled = true,
				range = 12,
				render_power = 3,
			},
			blur = {
				enabled = true,
				size = 6,
				passes = 3,
				popups = true,
			},
		},

		animations = {
			enabled = true,
		},
	})

	hl.curve("omh", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
	hl.curve("omhOut", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "omh", style = "popin 85%" })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "omhOut", style = "popin 85%" })
	hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "omhOut" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "omh", style = "slide" })
	hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "omh", style = "fade" })
end
