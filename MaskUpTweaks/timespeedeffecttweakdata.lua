Hooks:PostHook(TimeSpeedEffectTweakData, "_init_base_effects", "_init_base_effects_sw", function(self)
	self.mask_on = {
		sustain = 0,
		timer = "pausable",
		speed = 0,
		fade_out = 0,
		fade_in = 0,
		fade_in_delay = 0,
	}

	self.mask_on_player = {
		speed = 0.5,
		affect_timer = "player",
		fade_in_delay = self.mask_on.fade_in_delay,
		fade_in = self.mask_on.fade_in,
		sustain = self.mask_on.sustain,
		fade_out = self.mask_on.fade_out,
		timer = self.mask_on.timer,
	}
end)
