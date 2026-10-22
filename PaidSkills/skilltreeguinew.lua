local small_font_size = tweak_data.menu.pd2_small_font_size

-- forgive me for my sins but i have to override this entire function just to add "+ $x" 😭😭😭
local function _update_description(self, item)
	local desc_panel = self._panel:child("InfoRootPanel"):child("DescriptionPanel")
	local text = desc_panel:child("DescriptionText")
	local tier = item:tier()
	local skill_id = item:skill_id()
	local tweak_data_skill = tweak_data.skilltree.skills[skill_id]
	local skill_stat_color = tweak_data.screen_colors.resource
	local color_replace_table = {}
	local points = self._skilltree:points() or 0
	local basic_cost = self._skilltree:get_skill_points(skill_id, 1) or 0
	local pro_cost = self._skilltree:get_skill_points(skill_id, 2) or 0
	local talent = tweak_data.skilltree.skills[skill_id]
	local unlocked = self._skilltree:skill_unlocked(nil, skill_id)
	local step = self._skilltree:next_skill_step(skill_id)
	local completed = self._skilltree:skill_completed(skill_id)
	local skill_descs = tweak_data.upgrades.skill_descs[skill_id] or {
		0,
		0,
	}
	local basic_color_index = 1
	local pro_color_index = 2 + (skill_descs[1] or 0)

	if step > 1 then
		basic_cost = utf8.to_upper(managers.localization:text("st_menu_skill_owned"))
		color_replace_table[basic_color_index] = tweak_data.screen_colors.resource
	else
		basic_cost = managers.localization:text(basic_cost == 1 and "st_menu_point" or "st_menu_point_plural", {
			points = basic_cost,
		}) .. " + $" .. managers.money:add_decimal_marks_to_string(
			tostring(PaidSkills.prices[tier] and PaidSkills.prices[tier][1] or 0)
		)
	end

	if step > 2 then
		pro_cost = utf8.to_upper(managers.localization:text("st_menu_skill_owned"))
		color_replace_table[pro_color_index] = tweak_data.screen_colors.resource
	else
		pro_cost = managers.localization:text(pro_cost == 1 and "st_menu_point" or "st_menu_point_plural", {
			points = pro_cost,
		}) .. " + $" .. managers.money:add_decimal_marks_to_string(
			tostring(PaidSkills.prices[tier] and PaidSkills.prices[tier][2] or 0)
		)
	end

	local macroes = {
		basic = basic_cost,
		pro = pro_cost,
	}

	for i, d in pairs(skill_descs) do
		macroes[i] = d
	end

	local skill_btns = tweak_data.upgrades.skill_btns[skill_id]

	if skill_btns then
		for i, d in pairs(skill_btns) do
			macroes[i] = d()
		end
	end

	local basic_cost = managers.skilltree:skill_cost(tier, 1)
	local aced_cost = managers.skilltree:skill_cost(tier, 2)
	local skill_string = managers.localization:to_upper_text(tweak_data_skill.name_id)
	local cost_string =
		managers.localization:to_upper_text(basic_cost == 1 and "st_menu_skill_cost_singular" or "st_menu_skill_cost", {
			basic = basic_cost,
			aced = aced_cost,
		})
	local desc_string = managers.localization:text(tweak_data.skilltree.skills[skill_id].desc_id, macroes)
	local full_string = skill_string .. "\n\n" .. desc_string

	if (_G.IS_VR or managers.user:get_setting("show_vr_descs")) and tweak_data.vr.skill_descs_addons[skill_id] then
		local addon_data = tweak_data.vr.skill_descs_addons[skill_id]
		local vr_addon = managers.localization:text(addon_data.text_id, addon_data.macros)
		full_string = full_string .. "\n\n" .. managers.localization:text("menu_vr_skill_addon") .. "\n" .. vr_addon
	end

	text:set_text(full_string)
	managers.menu_component:make_color_text(text)
	text:set_font_size(small_font_size)

	local _, _, _, h = text:text_rect()

	while h > desc_panel:h() - text:top() do
		text:set_font_size(text:font_size() * 0.98)

		_, _, _, h = text:text_rect()
	end
end

local function invest_point(self, item)
	local skill_id = item:skill_id()
	local step = self._skilltree:next_skill_step(skill_id)
	local unlocked = self._skilltree:skill_unlocked(nil, skill_id)
	local completed = self._skilltree:skill_completed(skill_id)
	local skill_data = tweak_data.skilltree.skills[skill_id]

	if not unlocked then
		item:flash()

		return
	end

	if completed then
		item:flash()

		return
	end

	local cash_cost = PaidSkills:get_cash_cost_for_skill(skill_id, managers.skilltree:next_skill_step(skill_id))

	if self._skilltree:has_enough_skill_points(skill_id) and managers.money:total() >= cash_cost then
		local skill_name_localized = managers.localization:to_upper_text(skill_data.name_id)
		local to_unlock = managers.skilltree:next_skill_step(skill_id)
		local points = managers.skilltree:get_skill_points(skill_id, to_unlock) or 0

		local yes_func = function(...)
			if not item:invest() then
				-- this probably should never happen but just in case
				return
			end

			local panel = item:panel()

			SimpleGUIEffectSpewer.infamous_up(panel:world_center_x(), panel:world_center_y(), self._fullscreen_panel)
			self:on_notify(item:tree(), {
				label = "refresh",
			})
			managers.menu_component:post_event("menu_skill_investment")
			self:update_item()
			self:reload_connections()
			WalletGuiObject.refresh()
			self:refresh_reset_skills_legends(self._selected_page:trees_idx())
		end

		if PaidSkills.settings.no_confirmation then
			yes_func()
		else
			managers.system_menu:show({
				title = managers.localization:text("dialog_skills_place_title"),
				text = managers.localization:text("dialog_allocate_skillpoint", {
					skill = skill_name_localized .. " " .. managers.localization:text(
						to_unlock == 1 and "paidskills_basic" or "paidskills_ace"
					),
					points = points,
					remaining_points = managers.skilltree:points(),
					cost = managers.experience:cash_string(cash_cost),
				}),

				button_list = {
					{ -- yes button
						text = managers.localization:text("dialog_yes"),
						callback_func = yes_func,
					},

					{ -- no button
						text = managers.localization:text("dialog_no"),
						callback_func = function() end,
						cancel_button = true,
					},
				},

				focus_button = 1,

				no_upper = true,
			})
		end
	else
		item:flash()
	end
end

local function refund_point(self, item)
	local skill_id = item:skill_id()
	local step = self._skilltree:next_skill_step(skill_id)
	local completed = self._skilltree:skill_completed(skill_id)
	local skill_data = tweak_data.skilltree.skills[skill_id]
	local can_refund = item:can_refund()

	if not can_refund then
		item:flash()
		return
	end

	local to_unlock = managers.skilltree:skill_step(skill_id)

	local yes_func = function(...)
		if not item:refund() then
			-- again, no way this happens, but what if... 🤔
			item:flash()
			return
		end

		self:on_notify(item:tree(), {
			label = "refresh",
		})
		managers.menu_component:post_event("menu_skill_investment")
		self:update_item()
		self:reload_connections()
		WalletGuiObject.refresh()
		self:refresh_reset_skills_legends(self._selected_page:trees_idx())
	end

	if PaidSkills.settings.no_confirmation then
		yes_func()
		return
	end

	managers.system_menu:show({
		title = managers.localization:text("dialog_skills_place_title"),

		text = managers.localization:text("paidskills_skill_respec", {
			skill_name = managers.localization:to_upper_text(skill_data.name_id) .. " " .. managers.localization:text(
				to_unlock == 1 and "paidskills_basic" or "paidskills_ace"
			),
			refund_points = managers.skilltree:get_skill_points(skill_id, to_unlock) or 0,
			refund_cash_perc = PaidSkills.refund_mult * 100.0,
		}),

		button_list = {
			{ -- yes button
				text = managers.localization:text("dialog_yes"),
				callback_func = yes_func,
			},

			{ -- no button
				text = managers.localization:text("dialog_no"),
				callback_func = function(...) end,
				cancel_button = true,
			},
		},

		focus_button = 1,

		no_upper = true,
	})
end

local function respec_page(self, page)
	if PaidSkills.settings.no_confirmation then
		self:_dialog_respec_trees_yes(page:trees_idx())
		return
	end

	managers.system_menu:show({
		title = managers.localization:text("dialog_skills_respec_title"),

		text = managers.localization:text("paidskills_tree_respec", {
			skill_tree = managers.localization:text(tweak_data.skilltree.skilltree[page:name()].name_id),
			refund_cash_perc = PaidSkills.refund_mult * 100.0,
		}),

		button_list = {
			{ -- yes button
				text = managers.localization:text("dialog_yes"),
				callback_func = callback(self, self, "_dialog_respec_trees_yes", page:trees_idx()),
			},

			{ -- no button
				text = managers.localization:text("dialog_no"),
				callback_func = callback(self, self, "_dialog_respec_no"),
				cancel_button = true,
			},
		},

		focus_button = 2,

		no_upper = true,
	})
end

local function respec_all(self)
	if PaidSkills.settings.no_confirmation then
		self:_dialog_respec_all_yes()
		return
	end

	managers.system_menu:show({
		title = managers.localization:text("dialog_skills_respec_title"),

		text = managers.localization:text("paidskills_all_trees_respec", {
			refund_cash_perc = PaidSkills.refund_mult * 100.0,
		}),

		button_list = {
			{ -- yes button
				text = managers.localization:text("dialog_yes"),
				callback_func = callback(self, self, "_dialog_respec_all_yes"),
			},

			{ -- no button
				text = managers.localization:text("dialog_no"),
				callback_func = callback(self, self, "_dialog_respec_no"),
				cancel_button = true,
			},
		},

		focus_button = 2,

		no_upper = true,
	})
end

-- this one is justifiably overriden cuz i need to change the invest condition
local function invest(self)
	local refresh = false
	local skill_id = self._skill_id

	local cash_cost = PaidSkills:get_cash_cost_for_skill(skill_id, managers.skilltree:next_skill_step(skill_id))

	if
		self._skilltree:has_enough_skill_points(skill_id)
		and managers.money:total() >= cash_cost
		and self._skilltree:unlock(skill_id)
	then
		local skill_step = self._skilltree:skill_step(skill_id)
		local points = self._skilltree:skill_cost(self._tier, skill_step)
		local skill_points = self._skilltree:spend_points(points)

		managers.money:deduct_from_spending(cash_cost)

		self._gui:set_skill_point_text(skill_points)
		self._skilltree:_set_points_spent(self._tree, self._skilltree:points_spent(self._tree) + points)
		self:refresh(self._locked)

		refresh = true
	end

	return refresh
end

local function refund(self)
	local skill_tree = self._skilltree
	local skill_id = self._skill_id
	local skill_level = skill_tree:skill_step(skill_id)
	local refresh = false

	if skill_level > 0 then
		local tier = self._tier
		local tree = self._tree

		local cash_cost = PaidSkills:get_cash_refund_amount_for_skill(skill_id)

		if skill_tree:refund_skill(tree, tier, skill_id) then
			local cost = skill_tree:skill_cost(tier, skill_level)
			local skill_points = skill_tree:refund_points(cost)

			managers.money:add_to_spending(cash_cost)

			self._gui:set_skill_point_text(skill_points)
			self._skilltree:_set_points_spent(tree, skill_tree:points_spent(tree) - cost)
			self:refresh(self._locked)

			refresh = true
		end
	end

	return refresh
end

Hooks:OverrideFunction(NewSkillTreeGui, "invest_point", invest_point)
Hooks:OverrideFunction(NewSkillTreeGui, "refund_point", refund_point)
Hooks:OverrideFunction(NewSkillTreeGui, "respec_page", respec_page)
Hooks:OverrideFunction(NewSkillTreeGui, "respec_all", respec_all)
Hooks:OverrideFunction(NewSkillTreeGui, "_update_description", _update_description)
Hooks:OverrideFunction(NewSkillTreeSkillItem, "invest", invest)
Hooks:OverrideFunction(NewSkillTreeSkillItem, "refund", refund)
