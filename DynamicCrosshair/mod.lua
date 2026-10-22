if not DynamicCrosshair then
	DynamicCrosshair = {
		HIT_TYPES = {
			STANDARD = 0,
			HEADSHOT = 1,
			CRITICAL = 2,
		},

		mod_path = ModPath,

		-- TODO make settings page in mod options
		settings = {
			length = 10.0,
			default_spread = 14.0,
			spread_speed = 30.0,
			hit_time = 0.35,
			default_color = Color.white,
			hit_color = Color.red,
			headshot_color = Color(1.0, 1.0, 0.7843137254901961, 0.0),
			crit_color = Color.purple,
		},

		_required = {},
	}
end

if RequiredScript and not DynamicCrosshair._required[RequiredScript] then
	local fname = DynamicCrosshair.mod_path .. RequiredScript:gsub(".+/(.+)", "%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	DynamicCrosshair._required[RequiredScript] = true
end
