local end_delay = 5.0

local function find_and_update_mission_end_delay(current, checked)
	if not current or checked[current] then
		return false
	end
	checked[current] = true

	for _, params in pairs(current._values.on_executed) do
		local element = current:get_mission_element(params.id)

		if
			getmetatable(element) == ElementMissionEnd
			-- some mission scripts have it intentionally set to 0 for instant escape
			-- keep that, cuz otherwise car shop would suck
			and params.delay > 0
		then
			params.delay = end_delay
			return true
		end

		if find_and_update_mission_end_delay(element, checked) then
			return true
		end
	end

	return false
end

Hooks:PostHook(ElementAreaTrigger, "on_set_enabled", "wd_on_set_enabled", function(self)
	find_and_update_mission_end_delay(self, self)
end)
