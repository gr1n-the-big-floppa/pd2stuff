local clover_idx = 7
local bonnie_idx = 10

local function swap(tbl1, tbl2, key)
	local t = tbl2[key]
	tbl2[key] = tbl1[key]
	tbl1[key] = t
end

swap(
	tweak_data.criminals.characters[clover_idx].static_data,
	tweak_data.criminals.characters[bonnie_idx].static_data,
	"voice"
)

swap(
	tweak_data.criminals.characters[clover_idx].static_data,
	tweak_data.criminals.characters[bonnie_idx].static_data,
	"ssuffix"
)
