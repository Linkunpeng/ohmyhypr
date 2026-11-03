-- ==============================================================================
-- ohmyhypr — an AI native Hyprland desktop
-- Entry point. Requires Hyprland 0.56+ (Lua config).
--
-- Layout:
--   lua/omh/settings.lua  defaults + machine-local overrides (omh/local.lua)
--   lua/omh/*.lua         one concern per module, each returns `function(s)`
-- ==============================================================================

---@module 'hl'

local ROOT = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
-- Marks this session as ohmyhypr (`omh theme apply` checks it via `hyprctl repl`).
OHMYHYPR_ROOT = ROOT
package.path = ROOT .. "lua/?.lua;" .. ROOT .. "lua/?/init.lua;" .. package.path

local s = require("omh.settings")(ROOT)
-- The bar launches s.terminal / s.files / s.browser through `hyprctl dispatch`.
OHMYHYPR_SETTINGS = s

for _, name in ipairs({ "env", "monitors", "look", "input", "rules", "binds", "ai", "autostart" }) do
	require("omh." .. name)(s)
end

if s.local_setup then
	s.local_setup(s)
end
