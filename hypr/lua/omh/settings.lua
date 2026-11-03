-- Defaults shared by every module. Override per machine in omh/local.lua
-- (gitignored, see local.example.lua).

local function merge(dst, src)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dst[k]) == "table" then
			merge(dst[k], v)
		else
			dst[k] = v
		end
	end
	return dst
end

local function file_exists(path)
	local f = io.open(path, "r")
	if f then
		f:close()
		return true
	end
	return false
end

-- Theme state written by `omh theme apply` (palette, shape, effects).
local function load_theme()
	local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
	local path = state .. "/ohmyhypr/theme.lua"
	if not file_exists(path) then
		return nil
	end
	local ok, theme = pcall(dofile, path)
	return ok and theme or nil
end

return function(root)
	local repo = root:gsub("hypr/$", "")

	local s = {
		root = root,
		repo = repo,
		shell_dir = repo .. "shell",

		mod = "SUPER",
		terminal = "kitty",
		dropdown_terminal = repo .. "scripts/dropdown-terminal.sh",
		screenshot = repo .. "scripts/screenshot.sh",
		files = "thunar",
		browser = "chromium",
		-- Fallback launcher while the Quickshell omnibox is not running.
		launcher = "rofi -show drun",
		-- ohmyhypr CLI, run straight from this checkout.
		omh = repo .. "bin/omh",
		-- Applied on first start when no theme has been chosen yet.
		default_theme = "moonlantern",

		-- Monitors used when local.lua does not define any.
		monitors = {
			{ output = "", mode = "preferred", position = "auto", scale = 1 },
		},

		-- Fallback look; `omh theme apply <id>` overrides it via theme.lua.
		theme = {
			id = "builtin",
			palette = {
				accent = "rgba(8aadf4ff)",
				accent_alt = "rgba(c6a0f6ff)",
				border_active = "rgba(8aadf4ff)",
				border_inactive = "rgba(494d6488)",
				shadow = "rgba(181926ff)",
			},
			shape = { radius = 12, border = 2, gaps_in = 5, gaps_out = 10 },
			effects = { blur = true, shadow = true, dim_inactive = false, animation = "smooth", active_opacity = 1.0, inactive_opacity = 1.0 },
		},
	}

	local theme = load_theme()
	if theme then
		merge(s.theme, theme)
	end

	local local_file = root .. "lua/omh/local.lua"
	if file_exists(local_file) then
		local overrides = require("omh.local")
		if overrides.settings then
			merge(s, overrides.settings)
		end
		s.local_setup = overrides.setup
	end

	return s
end
