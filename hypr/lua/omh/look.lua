-- Look is fully theme-driven (s.theme, from `omh theme apply`).

local ANIMATIONS = {
	smooth = { speed = 5, out = 3, style = "popin 85%", ws = "slide" },
	snappy = { speed = 2.5, out = 1.5, style = "slide", ws = "slidefade 20%" },
}

return function(s)
	local p, shape, fx = s.theme.palette, s.theme.shape, s.theme.effects

	hl.config({
		general = {
			border_size = shape.border,
			gaps_in = shape.gaps_in,
			gaps_out = shape.gaps_out,
			resize_on_border = true,
			layout = "dwindle",
			col = {
				active_border = p.border_active,
				inactive_border = p.border_inactive,
			},
		},

		dwindle = {
			preserve_split = true,
		},

		decoration = {
			rounding = shape.radius,
			dim_inactive = fx.dim_inactive,
			dim_strength = 0.12,
			shadow = {
				enabled = fx.shadow,
				range = 14,
				render_power = 3,
				color = p.shadow,
			},
			blur = {
				enabled = fx.blur,
				size = 6,
				passes = 3,
				popups = true,
			},
		},

		animations = {
			enabled = fx.animation ~= "none",
		},
	})

	local a = ANIMATIONS[fx.animation] or ANIMATIONS.smooth
	hl.curve("omh", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
	hl.curve("omhOut", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })

	hl.animation({ leaf = "windows", enabled = true, speed = a.speed, bezier = "omh", style = a.style })
	hl.animation({ leaf = "windowsOut", enabled = true, speed = a.out, bezier = "omhOut", style = a.style })
	hl.animation({ leaf = "fade", enabled = true, speed = a.out, bezier = "omhOut" })
	hl.animation({ leaf = "workspaces", enabled = true, speed = a.speed, bezier = "omh", style = a.ws })
	hl.animation({ leaf = "layers", enabled = true, speed = a.out, bezier = "omh", style = "fade" })
end
