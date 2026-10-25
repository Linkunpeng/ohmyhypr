return function(s)
	-- Blur behind every ohmyhypr shell surface (Quickshell sets the namespace).
	hl.layer_rule({
		name = "omh-shell-blur",
		match = { namespace = "^omh-(bar|omnibox|themes)$" },
		blur = true,
		ignore_alpha = 0.3,
	})

	hl.window_rule({
		name = "omh-suppress-maximize",
		match = { class = ".*" },
		suppress_event = "maximize",
	})

	hl.window_rule({
		name = "omh-float-dialogs",
		match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|org.pulseaudio.pavucontrol)$" },
		float = true,
	})
end
