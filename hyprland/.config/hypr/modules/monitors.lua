-- Monitors. Any screen: its preferred mode, placed automatically, scale
-- picked by Hyprland. Your own rules (exact mode, refresh rate, scale,
-- position) go in monitors.local.lua next to this file: it is loaded after
-- this one, is not part of the repo, and is where orrery-scale saves the
-- scale you pick (Menu > Style > Display scale). `hyprctl monitors all`
-- lists outputs and modes, e.g.
--   hl.monitor({ output = "eDP-1", mode = "2560x1440@165.00", position = "auto", scale = 1.6 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local f = io.open(os.getenv("HOME") .. "/.config/hypr/modules/monitors.local.lua")
if f then f:close(); pcall(dofile, os.getenv("HOME") .. "/.config/hypr/modules/monitors.local.lua") end
