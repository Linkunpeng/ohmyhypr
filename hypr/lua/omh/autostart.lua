return function(s)
	-- `make dev` runs a nested Hyprland inside the current session; skip
	-- session-wide daemons there so they don't fight the host's instances.
	local nested = os.getenv("OHMYHYPR_NESTED") == "1"

	local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	local has_theme = io.open(state .. "/ohmyhypr/theme.json", "r")
	if has_theme then
		has_theme:close()
	end

	hl.on("hyprland.start", function()
		if not has_theme then
			hl.exec_cmd(s.omh .. " theme apply " .. s.default_theme)
		end
		hl.exec_cmd("qs -p " .. s.shell_dir)

		if nested then
			return
		end

		hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP OHMYHYPR_ROOT")
		hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP OHMYHYPR_ROOT")
		hl.exec_cmd(string.format("%q idle", s.omh))
		hl.exec_cmd("fcitx5")
		hl.exec_cmd("wl-paste --type text --watch cliphist store")
		hl.exec_cmd("wl-paste --type image --watch cliphist store")
	end)
end
