return function(s)
	-- Blur visible panels, but not the full-screen notification dismiss surface.
	-- The bar stays unblurred like the waybar it mirrors.
	hl.layer_rule({
		name = "omh-shell-blur",
		match = { namespace = "^omh-(omnibox|themes|notifications)$" },
		blur = true,
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
