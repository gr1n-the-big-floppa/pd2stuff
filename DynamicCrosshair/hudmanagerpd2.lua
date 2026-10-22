local function lerp(a, b, k)
	return a + (b - a) * k
end

local ARMS = { "_above", "_below", "_right", "_left", "_center_dot" }
local function for_each_arm(self, method, ...)
	for _, arm in ipairs(ARMS) do
		self[arm][method](self[arm], ...)
	end
end

local HIT_COLOR_MAP = {
	[DynamicCrosshair.HIT_TYPES.STANDARD] = "hit_color",
	[DynamicCrosshair.HIT_TYPES.HEADSHOT] = "headshot_color",
	[DynamicCrosshair.HIT_TYPES.CRITICAL] = "crit_color",
}

HUDCrosshair = HUDCrosshair or class()

local function make_bitmap(panel, name, w, h, color, visible)
	return panel:bitmap({
		visible = visible ~= false,
		name = name,
		layer = 0,
		w = w,
		h = h,
		color = color,
	})
end

function HUDCrosshair:init(hud)
	self._hud_panel = hud.panel
	local panel = self._hud_panel
	local center = panel:center()
	local settings = DynamicCrosshair.settings
	local color = settings.default_color

	self._main = make_bitmap(panel, "_main", settings.default_spread, settings.default_spread, nil, false)
	self._main:set_center(center)

	self._left = make_bitmap(panel, "_left", settings.length, 1, color)
	self._right = make_bitmap(panel, "_right", settings.length, 1, color)
	self._above = make_bitmap(panel, "_above", 1, settings.length, color)
	self._below = make_bitmap(panel, "_below", 1, settings.length, color)
	self._center_dot = make_bitmap(panel, "_center_dot", 1, 1, color)

	self:_snap_arms_to_main()

	self._crosshair_spread_deg = 0

	managers.hud:add_updator("dc_crosshair_update", callback(self, self, "update"))
end

function HUDCrosshair:_snap_arms_to_main()
	local main = self._main
	self._left:set_center(main:center())
	self._left:set_right(main:left())

	self._right:set_center(main:center())
	self._right:set_left(main:right())

	self._above:set_center(main:center())
	self._above:set_bottom(main:top())

	self._below:set_center(main:center())
	self._below:set_top(main:bottom())

	self._center_dot:set_center(main:center())
end

local function get_spread_deg(player_unit, weapon_unit_base)
	local spread_x, spread_y = weapon_unit_base:_get_spread(player_unit)
	spread_x = math.max(spread_x or 0, 0)
	spread_y = math.max(spread_y or 0, 0)
	return math.max(spread_x, spread_y)
end

local SPREAD_PROJECTION_DISTANCE = 1000
local mvec_forward = Vector3()
local mvec_right = Vector3()
local mvec_center_point = Vector3()
local mvec_edge_point = Vector3()
local mvec_center_screen = Vector3()
local mvec_edge_screen = Vector3()

local function project_spread_diameter(spread_deg, cam, workspace)
	if spread_deg <= 0 then
		return 0
	end

	local cam_pos = cam:position()
	local rot = cam:rotation()

	mvector3.set(mvec_forward, rot:y())
	mvector3.set(mvec_right, rot:x())
	local forward, right = mvec_forward, mvec_right

	local edge_dir = forward * math.cos(spread_deg) + right * math.sin(spread_deg)

	mvector3.set(mvec_center_point, cam_pos)
	mvector3.add(mvec_center_point, forward * SPREAD_PROJECTION_DISTANCE)

	mvector3.set(mvec_edge_point, cam_pos)
	mvector3.add(mvec_edge_point, edge_dir * SPREAD_PROJECTION_DISTANCE)

	mvector3.set(mvec_center_screen, workspace:world_to_screen(cam, mvec_center_point))
	mvector3.set(mvec_edge_screen, workspace:world_to_screen(cam, mvec_edge_point))

	return 2 * math.abs(mvector3.x(mvec_edge_screen) - mvector3.x(mvec_center_screen))
end

function HUDCrosshair:update(t, dt)
	local player_unit = managers.player:player_unit()
	if not alive(player_unit) then
		return
	end

	local weapon_unit = managers.player:equipped_weapon_unit()
	if not weapon_unit then
		return
	end

	local weapon_base = weapon_unit:base()
	if not weapon_base then
		return
	end

	local movement = player_unit:movement()
	if not movement then
		return
	end

	local state = movement._current_state

	local should_show = not state:in_steelsight() and not state:_interacting()
	for_each_arm(self, "set_visible", should_show)

	self:_update_hit_flash(dt)
	self:_update_spread(player_unit, weapon_base, dt)
end

function HUDCrosshair:_update_hit_flash(dt)
	if not self._hit_time then
		return
	end

	local color_key = HIT_COLOR_MAP[self._hit_type]
	if color_key then
		for_each_arm(self, "set_color", DynamicCrosshair.settings[color_key])
	end

	self._hit_time = self._hit_time - dt
	if self._hit_time <= 0 then
		for_each_arm(self, "set_color", DynamicCrosshair.settings.default_color)
		self._hit_time = nil
		self._hit_type = nil
	end
end

function HUDCrosshair:_update_spread(player_unit, weapon_base, dt)
	local settings = DynamicCrosshair.settings
	local cam = player_unit:camera()._camera_object
	local workspace = managers.hud:workspace("saferect")
	local state = player_unit:movement():current_state()

	local target_spread_deg = 0
	if alive(state._equipped_unit) then
		target_spread_deg = get_spread_deg(player_unit, state._equipped_unit:base())
	end

	local lerp_t = math.min(dt * settings.spread_speed, 1.0)
	self._crosshair_spread_deg = lerp(self._crosshair_spread_deg, target_spread_deg, lerp_t)

	local diameter = settings.default_spread
	if alive(state._equipped_unit) and self._crosshair_spread_deg > 0 then
		diameter = project_spread_diameter(self._crosshair_spread_deg, cam, workspace)
	end

	local spread = diameter
	self._main:set_width(spread)
	self._main:set_height(spread)
	self._main:set_center(self._hud_panel:center())

	self:_snap_arms_to_main()
end

Hooks:PostHook(HUDManager, "_setup_player_info_hud_pd2", "_dc_setup_player_info_hud_pd2", function(self)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2)
	self._hud_crosshair = HUDCrosshair:new(hud)
end)
