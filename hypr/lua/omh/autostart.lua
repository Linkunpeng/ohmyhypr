return function(s)
	-- `make dev` runs a nested Hyprland inside the current session; skip
	-- session-wide daemons there so they don't fight the host's instances.
	local nested = os.getenv("OHMYHYPR_NESTED") == "1"

	hl.on("hyprland.start", function()
		hl.exec_cmd("qs -p " .. s.shell_dir)

		if nested then
			return
		end

		hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP OHMYHYPR_ROOT")
		hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP OHMYHYPR_ROOT")
		hl.exec_cmd("swaync")
		hl.exec_cmd("hypridle")
		hl.exec_cmd("fcitx5")
		hl.exec_cmd("wl-paste --type text --watch cliphist store")
		hl.exec_cmd("wl-paste --type image --watch cliphist store")
	end)
end
