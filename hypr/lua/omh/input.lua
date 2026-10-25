return function(s)
	hl.config({
		input = {
			kb_layout = "us",
			kb_options = "ctrl:nocaps",
			repeat_rate = 50,
			repeat_delay = 300,
			follow_mouse = 1,
			numlock_by_default = true,
			touchpad = {
				natural_scroll = true,
				disable_while_typing = true,
				tap_to_click = true,
			},
		},

		misc = {
			disable_hyprland_logo = true,
			disable_splash_rendering = true,
		},
	})
end
