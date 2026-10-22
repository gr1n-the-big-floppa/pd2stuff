Hooks:PostHook(PlayerMaskOff, "_update_check_actions", "_update_check_actions_sw", function(self, t, dt)
	local input = self:_get_input(t, dt)
	self:_check_change_weapon(t, input)
end)

function PlayerMaskOff:_check_change_weapon(t, input)
	local selection_wanted = input.btn_primary_choice
	local action_wanted = input.btn_switch_weapon_press

	if selection_wanted then
		self:_change_weapon(t, {
			selection_wanted = selection_wanted,
		})
	elseif action_wanted then
		self:_change_weapon(t, {
			next = true,
		})
	end
end

function PlayerMaskOff:_change_weapon(t, data)
	local selection_wanted = data.selection_wanted

	if data.next then
		local _, next_selection = self._ext_inventory:get_next_selection()
		selection_wanted = next_selection
	elseif data.previous then
		local _, previous_selection = self._ext_inventory:get_previous_selection()
		selection_wanted = previous_selection
	end

	self._ext_inventory:show_equipped_unit()

	self._ext_inventory:equip_selection(selection_wanted, false)
	managers.upgrades:setup_current_weapon()

	-- hide the new one for now because some weapons (e.g. rattlesnake) have weird idle poses that cover half the screen
	self._ext_inventory:hide_equipped_unit()
end

Hooks:PreHook(PlayerMaskOff, "_check_use_item", "_check_use_item_sw", function(self, t, input)
	local pressed, released, holding = nil

	if self._start_standard_expire_t and not self._interact_expire_t then
		pressed, released, holding = self:_check_tap_to_interact_inputs(
			t,
			input.btn_use_item_press,
			input.btn_use_item_release,
			input.btn_use_item_state
		)
	else
		holding = input.btn_use_item_state
		released = input.btn_use_item_release
		pressed = input.btn_use_item_press
	end

	if pressed then
		self._ext_inventory:show_equipped_unit()
		self:_end_action_start_standard()

		-- lie that no G button was pressed to the og function :)
		-- this prevents "PREPARING MASK" text being stuck
		input.btn_use_item_press = false
		input.btn_use_item_release = false
	end
end)
