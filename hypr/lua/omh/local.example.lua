-- Copy to local.lua (gitignored) for machine-specific settings.
--   settings: merged into omh.settings
--   setup(s): runs last, may call any hl.* API

return {
	settings = {
		terminal = "kitty",
		monitors = {
			{ output = "DP-1", mode = "preferred", position = "0x0", scale = 1.5 },
			{ output = "DP-2", mode = "highres", position = "2560x0", scale = 1, transform = 1 },
			{ output = "", mode = "preferred", position = "auto", scale = 1 },
		},
	},

	setup = function(s)
		hl.env("LIBVA_DRIVER_NAME", "nvidia")
		hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
		hl.env("NVD_BACKEND", "direct")
	end,
}
