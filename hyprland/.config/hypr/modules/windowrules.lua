-------------------
---- LAYER RULES --
-------------------

-- SwayNotificationCenter
hl.layer_rule({
	match = { namespace = "^swaync-control-center$" },
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	match = { namespace = "^swaync-notification-window$" },
	blur = true,
	ignore_alpha = 0.4,
})

hl.layer_rule({
	match = { namespace = "^logout_dialog$" },
	blur = true,
	ignore_alpha = 0.7,
})

-- The Quickshell shell: same blur as the tools it replaced
hl.layer_rule({ match = { namespace = "^hypr-powermenu$" },      blur = true, ignore_alpha = 0.7 })
hl.layer_rule({ match = { namespace = "^hypr-notifications$" },  blur = true, ignore_alpha = 0.4 })
hl.layer_rule({ match = { namespace = "^hypr-control-center$" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "^hypr-picker$" },         blur = true, ignore_alpha = 0.7 })
hl.layer_rule({ match = { namespace = "^hypr-launcher$" },       blur = true, ignore_alpha = 0.5, animation = "popin 65%" })
hl.layer_rule({ match = { namespace = "^hypr-clipboard$" },      blur = true, ignore_alpha = 0.5, animation = "popin 65%" })
hl.layer_rule({ match = { namespace = "^hypr-menu$" },           blur = true, ignore_alpha = 0.5, animation = "popin 65%" })
-- the bar's surface grows to the screen while a button is held on it (Bar.qml,
-- to keep drags over empty workspaces); animated, that resize stretched the bar
hl.layer_rule({ match = { namespace = "^hypr-bar$" },            no_anim = true })
hl.layer_rule({ match = { namespace = "^hypr-dock$" },           blur = true, ignore_alpha = 0.5 })

-- Rofi
hl.layer_rule({
	match = { namespace = "^rofi$" },
	blur = true,
	animation = "popin 65%",
})

--------------------
---- WINDOW RULES --
--------------------

-- floating terminal for menu actions (hypr-float, hypr-edit): centred, medium.
-- size takes expressions, not percentages ("60%" is silently ignored)
hl.window_rule({
	name = "hypr-float",
	match = { class = "^hypr-float$" },
	float = true,
	center = true,
	size = { "monitor_w * 0.78", "monitor_h * 0.82" },
})

hl.window_rule({
	name = "idle-inhibit-fullscreen",
	match = { fullscreen = true },
	idle_inhibit = "fullscreen",
})