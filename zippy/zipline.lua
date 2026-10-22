local speed_scale = 2.5

Hooks:PostHook(ZipLine, "set_usage_type", "zippy_set_usage_type", function(self, usage_type)
	if self:is_usage_type_bag() or self:is_usage_type_both() then
		self:set_speed(self._speed * speed_scale)
	end
end)
