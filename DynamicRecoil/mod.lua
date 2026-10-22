if not DynamicRecoil then
	DynamicRecoil = {
		mod_path = ModPath,

		_required = {},
	}
end

if RequiredScript and not DynamicRecoil._required[RequiredScript] then
	local fname = DynamicRecoil.mod_path .. RequiredScript:gsub(".+/(.+)", "%1.lua")
	if io.file_is_readable(fname) then
		dofile(fname)
	end

	DynamicRecoil._required[RequiredScript] = true
end
