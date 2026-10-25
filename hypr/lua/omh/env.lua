return function(s)
	hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
	hl.env("XDG_SESSION_DESKTOP", "Hyprland")
	hl.env("XDG_SESSION_TYPE", "wayland")
	hl.env("GDK_BACKEND", "wayland,x11,*")
	hl.env("QT_QPA_PLATFORM", "wayland;xcb")
	hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
	hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
	hl.env("MOZ_ENABLE_WAYLAND", "1")
	hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
	hl.env("XMODIFIERS", "@im=fcitx")

	-- Lets child processes (omh, shell) find the repo.
	hl.env("OHMYHYPR_ROOT", s.repo)
end
