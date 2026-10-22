Hooks:PreHook(SkillTreeManager, "_unaquire_skill", "_ps_unaquire_skill", function(self, skill_id)
	managers.money:add_to_spending(PaidSkills:get_cash_refund_amount_sum_for_skill(skill_id))
end)
