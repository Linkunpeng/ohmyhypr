return function(s)
	-- Blur visible panels, but not the full-screen notification dismiss surface.
	hl.layer_rule({
		name = "omh-shell-blur",
		match = { namespace = "^omh-(bar|omnibox|themes|notifications)$" },
		blur = true,
		-- Below the bar's lowest opacity (0.2) so translucent segments stay blurred.
		ignore_alpha = 0.1,
	})

	-- Video stays solid even when unfocused (themes may make inactive windows translucent).
	hl.window_rule({
		name = "omh-opaque-media",
		match = { class = "^(mpv|vlc|org.videolan.VLC|celluloid|io.github.celluloid_player.Celluloid)$" },
		opaque = true,
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
