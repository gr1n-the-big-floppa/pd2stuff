Hooks:PostHook(HUDHitConfirm, "on_hit_confirmed", "dc_on_hit_confirmed", function(self, damage_scale)
	managers.hud._hud_crosshair._hit_time = DynamicCrosshair.settings.hit_time
	managers.hud._hud_crosshair._hit_type = DynamicCrosshair.HIT_TYPES.STANDARD
end)

Hooks:PostHook(HUDHitConfirm, "on_crit_confirmed", "dc_on_crit_confirmed", function(self, damage_scale)
	managers.hud._hud_crosshair._hit_time = DynamicCrosshair.settings.hit_time
	managers.hud._hud_crosshair._hit_type = DynamicCrosshair.HIT_TYPES.CRITICAL
end)
