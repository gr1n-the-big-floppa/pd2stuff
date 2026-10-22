Hooks:PostHook(PlayerCamera, "play_shaker", "eclipse_shaker_play_shaker", function(self, effect, amplitude, ...)
	if _G.IS_VR or not Eclipse then
		return
	end

	-- really hacky UwU
	if effect == "fire_weapon_recoil" then
		self:play_shaker("fire_weapon_rot", 1 * amplitude)
	end
end)
