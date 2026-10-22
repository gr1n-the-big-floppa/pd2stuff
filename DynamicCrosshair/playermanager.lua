Hooks:PostHook(PlayerManager, "on_headshot_dealt", "dc_on_headshot_dealt", function(self)
	managers.hud._hud_crosshair._hit_time = DynamicCrosshair.settings.hit_time
	managers.hud._hud_crosshair._hit_type = DynamicCrosshair.HIT_TYPES.HEADSHOT
end)
