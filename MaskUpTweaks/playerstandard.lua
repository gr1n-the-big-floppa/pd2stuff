Hooks:PreHook(PlayerStandard, "enter", "enter_sw", function(self, state_data, new_state_name)
	self._state_data.mask_equipped = true -- skip mask up animation
end)
