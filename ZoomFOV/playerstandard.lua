local function get_zoom_fov(self, stance_data)
	local fov = stance_data and stance_data.FOV or 75
	local fov_multiplier = self._setting_fov_multiplier

	if self._state_data.in_steelsight then
		return self._equipped_unit:base():zoom()
	end

	return fov * fov_multiplier
end

Hooks:OverrideFunction(PlayerStandard, "get_zoom_fov", get_zoom_fov)
