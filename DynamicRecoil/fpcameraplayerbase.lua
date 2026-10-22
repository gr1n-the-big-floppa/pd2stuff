-- Sorry, Eclipse
if Eclipse then
	Hooks:RemovePostHook("ssr_stop_shooting")
end

local function reduce_towards_zero(value, amount)
	if not value or value == 0 then
		return value
	end

	if value > 0 then
		return math.max(value - amount, 0)
	else
		return math.min(value + amount, 0)
	end
end

local function _update_rot(self, axis, unscaled_axis)
	local t = managers.player:player_timer():time()
	local dt = t - (self._last_rot_t or t)

	local stick_input_x, stick_input_y = self._look_function(axis, self._input.look_multiplier, dt, unscaled_axis)

	local recoil = self._recoil_kick
	local h_recoil = recoil.h

	if stick_input_y < 0 then
		local amount = -stick_input_y

		recoil.to_reduce = reduce_towards_zero(recoil.to_reduce, amount)
		recoil.accumulated = reduce_towards_zero(recoil.accumulated, amount)
		recoil.current = reduce_towards_zero(recoil.current, amount)
	end

	if stick_input_x ~= 0 then
		local amount = math.abs(stick_input_x)

		h_recoil.to_reduce = reduce_towards_zero(h_recoil.to_reduce, amount)
		h_recoil.accumulated = reduce_towards_zero(h_recoil.accumulated, amount)
		h_recoil.current = reduce_towards_zero(h_recoil.current, amount)
	end
end

Hooks:PostHook(FPCameraPlayerBase, "_update_rot", "_dr_update_rot", _update_rot)
