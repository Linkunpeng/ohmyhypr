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

return function(root)
	local repo = root:gsub("hypr/$", "")

	local s = {
		root = root,
		repo = repo,
		shell_dir = repo .. "shell",

		mod = "SUPER",
		terminal = "kitty",
		files = "thunar",
		browser = "google-chrome-stable",
		-- Fallback launcher while the Quickshell omnibox is not running.
		launcher = "rofi -show drun",
		-- ohmyhypr CLI (brain). `uv tool install -e brain` puts it on PATH.
		omh = "omh",

		-- Monitors used when local.lua does not define any.
		monitors = {
			{ output = "", mode = "preferred", position = "auto", scale = 1 },
		},

		palette = {
			accent = "rgb(8aadf4)",
			accent_alt = "rgb(c6a0f6)",
			inactive = "rgba(494d6488)",
		},
	}

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
