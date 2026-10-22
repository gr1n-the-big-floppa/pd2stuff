-- Lua doesn't have modern 1_000_000 number syntax so...
local THOUSAND = 1000
local MILLION = 1000000

if not PaidSkills then
	PaidSkills = {
		mod_path = ModPath,
		save_file = SavePath .. "paidskills.json",
		mod_options = ModPath .. "settingsmenu.json",

		settings = {
			no_confirmation = false,
		},

		prices = Eclipse and {
			-- Eclipse prices (@sokolov49)
			{ -- tier 1
				4 * THOUSAND, -- basic (1 skill points)
				8 * THOUSAND, -- aced (3 skill points)
			},
			{ -- tier 2
				12 * THOUSAND, -- basic (2 skill points)
				20 * THOUSAND, -- aced (4 skill points)
			},
			{ -- tier 3
				32 * THOUSAND, -- basic (3 skill points)
				40 * THOUSAND, -- aced (6 skill points)
			},
			{ -- tier 4
				52 * THOUSAND, -- basic (4 skill points)
				60 * THOUSAND, -- aced (8 skill points)
			},
		} or {
			-- Vanilla prices
			{ -- tier 1
				25 * THOUSAND, -- basic (1 skill points)
				100 * THOUSAND, -- aced (3 skill points)
			},
			{ -- tier 2
				75 * THOUSAND, -- basic (2 skill points)
				300 * THOUSAND, -- aced (4 skill points)
			},
			{ -- tier 3
				250 * THOUSAND, -- basic (3 skill points)
				1 * MILLION, -- aced (6 skill points)
			},
			{ -- tier 4
				750 * THOUSAND, -- basic (4 skill points)
				3 * MILLION, -- aced (8 skill points)
			},
		},

		refund_mult = 0.5, -- only (refund_mult * skill_price) of skill's cost is refunded

		_required = {},
	}

	function PaidSkills:reset()
		self.settings.no_confirmation = false
		self:save()
	end

	function PaidSkills:load()
		local file = io.open(self.save_file, "r")
		if file then
			for key, value in pairs(json.decode(file:read("*all"))) do
				self.settings[key] = value
			end
			file:close()
		else
			self:reset()
		end
	end

	function PaidSkills:save()
		local file = io.open(self.save_file, "w+")
		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end

	function PaidSkills:get_cash_cost_for_skill(skill_id, step)
		local tier = tweak_data.skilltree:get_tier_position_from_skill_name(skill_id)
		local step = step or managers.skilltree:skill_step(skill_id)

		return self.prices[tier][step]
	end

	function PaidSkills:get_cash_refund_amount_for_skill(skill_id, step)
		if managers.skilltree:skill_step(skill_id) <= 0 then
			return 0
		end

		return self:get_cash_cost_for_skill(skill_id, step) * self.refund_mult
	end

	function PaidSkills:get_cash_refund_amount_sum_for_skill(skill_id, step)
		local step = step or managers.skilltree:skill_step(skill_id)

		if step <= 0 then
			return 0
		end

		local tier = tweak_data.skilltree:get_tier_position_from_skill_name(skill_id)

		local sum = 0

		for i = step, 1, -1 do
			local tier_price = self.prices[tier][i] * self.refund_mult
			sum = sum + tier_price
		end

		return sum
	end

	local function add_mod_options(menu_manager)
		if menu_manager == nil then
			return
		end

		MenuCallbackHandler.paidskills_save = function(node)
			PaidSkills:save()
		end

		MenuCallbackHandler.set_no_confirmation_value = function(self, item)
			PaidSkills.settings.no_confirmation = item:value() == "on"
		end

		MenuHelper:LoadFromJsonFile(PaidSkills.mod_options, PaidSkills, PaidSkills.settings)
	end

	Hooks:Add("MenuManagerInitialize", "PaidSkills_add_mod_options", add_mod_options)

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInit_PaidSkills", function(loc)
		local lang_key = SystemInfo:language():key()

		local languages = {
			[Idstring("english"):key()] = "english",
			[Idstring("russian"):key()] = "russian",
		}

		local path = PaidSkills.mod_path .. (languages[lang_key] or "english") .. ".json"

		if io.file_is_readable(path) then
			loc:load_localization_file(path, false)
		else
			loc:load_localization_file(PaidSkills.mod_path .. "english.json", false)
		end
	end)

	PaidSkills:load()
end

if RequiredScript and not PaidSkills._required[RequiredScript] then
	local fname = PaidSkills.mod_path .. RequiredScript:gsub(".+/(.+)", "%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	PaidSkills._required[RequiredScript] = true
end
