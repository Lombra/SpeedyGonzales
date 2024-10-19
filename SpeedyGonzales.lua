local _, Speedy = ...

local floor = math.floor
local GetUnitSpeed = GetUnitSpeed
local IsFlying = IsFlying
local IsSwimming = IsSwimming
local IsFalling = IsFalling

local BASE_WIDTH = 80

local db, selectedUnit
local speeder = "player"

-- data for the various unit displays
local unitData = {
	{
		key = "percent",
		label = "Percent",
		tooltip = "100% refers to on foot base running speed.",
		func = function(n) return floor(n / 7 * 100 + 0.1) end,
		display = "%",
		extraWidth = -16,
	},
	{
		key = "kilometers",
		label = "Kilometers per hour",
		func = function(n) return floor(n * 9.144 * 3.6 + 0.01) / 10 end,
		display = " km/h",
		extraWidth = 8,
	},
	{
		key = "miles",
		label = "Miles per hour",
		func = function(n) return floor(n / 1.76 * 36 + 0.01) / 10 end,
		display = " mph",
	},
	{
		key = "meters",
		label = "Meters per second",
		func = function(n) return floor(n * 9.144 + 0.01) / 10 end,
		display = " m/s",
	},
	{
		key = "yards",
		label = "Yards per second",
		func = function(n) return floor(n * 10 + 0.01) / 10 end,
		display = " yd/s",
	},
}

local function transform(speed)
	return selectedUnit.func(speed)
end

local dataobj = LibStub("LibDataBroker-1.1"):NewDataObject(..., {
	type = "data source",
	text = "Speed",
	icon = [[Interface\Icons\Ability_Rogue_Sprint]],
	label = "Speed",
	OnTooltipShow = function(self)
		local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed("player")
		local speed = runSpeed
		if IsSwimming() then
			speed = swimSpeed
		elseif IsFlying() then
			speed = flightSpeed
		end
		self:AddLine(format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..format("%d%%", transform(speed)), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
		self:AddLine(format(STAT_MOVEMENT_GROUND_TOOLTIP, transform(runSpeed)))
		self:AddLine(format(STAT_MOVEMENT_FLIGHT_TOOLTIP, transform(flightSpeed)))
		self:AddLine(format(STAT_MOVEMENT_SWIM_TOOLTIP, transform(swimSpeed)))
	end,
})

-- create the speed-o-meter frame
local addon = CreateFrame("Frame", "SpeedyGonzalesFrame", UIParent, "BackdropTemplate")
addon:SetHeight(32)
addon:SetMovable(true)
addon:SetToplevel(true)
addon:SetDontSavePosition(true)
addon:SetBackdrop({
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	edgeSize = 14,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
})
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
addon:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
addon:SetScript("OnEvent", function(self, event, ...)
	return self[event] and self[event](self, ...)
end)
addon:SetScript("OnMouseDown", addon.StartMoving)
addon:SetScript("OnMouseUp", function(self) self:OnMouseUp() end)
addon:SetScript("OnHide", function(self) self:OnMouseUp() end)

do
	local frame = CreateFrame("Frame")
	frame:Hide()
	frame:SetScript("OnUpdate", function(self)
		local speed
		if db.showTopSpeed then
			local flying = IsFlying()
			local swimming = IsSwimming()
			local _, runSpeed, flightSpeed, swimSpeed = GetUnitSpeed(speeder)

			-- Determine whether to display running, flying, or swimming speed
			speed = runSpeed
			if swimming then
				speed = swimSpeed
			elseif flying then
				speed = flightSpeed
			end

			-- Hack so that your speed doesn't appear to change when jumping out of the water
			if IsFalling() then
				if self.wasSwimming then
					speed = swimSpeed
				end
			else
				self.wasSwimming = swimming
			end

			speed = transform(speed)
		else
			local isGliding, canGlide, forwardSpeed = C_PlayerInfo.GetGlidingInfo()
			speed = transform(isGliding and forwardSpeed or GetUnitSpeed(speeder))
		end
		addon.text:SetFormattedText("%d%s", speed, selectedUnit.display)
		dataobj.text = format("%d%s", speed, selectedUnit.display)
	end)
	addon.updateFrame = frame
end

-- create font string for the actual speed text
addon.text = addon:CreateFontString()
addon.text:SetPoint("CENTER", addon)
addon.text:SetFontObject("GameFontHighlight")
addon.text:SetSpacing(2)

local category = Speedy.RegisterCategory("SpeedyGonzales")

local defaults = {
	units = "percent",
	shown = true,
	locked = false,
	showTopSpeed = false,
	pos = {
		point = "CENTER",
		xOff = 0,
		yOff = -100
	},
	backdropColor = {
		r = 0,
		g = 0,
		b = 0,
		a = 0.8,
	},
	borderColor = {
		r = 0.3,
		g = 0.3,
		b = 0.3,
		a = 1.0,
	},
}

local options = {
	{
		key = "shown",
		type = Settings.VarType.Boolean,
		defaultValue = defaults.shown,
		label = "Show",
		tooltip = "Enables the standalone display.",
		onChange = function() addon:SetVisibility() end,
	},
	{
		key = "locked",
		type = Settings.VarType.Boolean,
		defaultValue = defaults.locked,
		label = "Lock",
		tooltip = "Locks the standalone display, enabling clicking through it and preventing moving it.",
		onChange = function() addon:SetLock() end,
	},
	{
		key = "showTopSpeed",
		type = Settings.VarType.Boolean,
		defaultValue = defaults.showTopSpeed,
		label = "Show top speed",
		tooltip = "Shows the maximum possible speed in the current vehicle instead of the current speed. May display incorrect values while skyriding.",
	},
	{
		key = "units",
		type = Settings.VarType.String,
		defaultValue = defaults.units,
		label = "Units",
		tooltip = "Selects the unit by which to represent speed.",
		options = function()
			local container = Settings.CreateControlTextContainer()
			for i, option in ipairs(unitData) do
				container:Add(option.key, option.label, option.tooltip)
			end
			return container:GetData()
		end,
		onChange = function(setting, value) addon:SetUnit(value) end,
	},
	{
		key = "backdropColor",
		type = "color",
		defaultValue = defaults.backdropColor,
		label = "Background color",
		tooltip = "Sets the background color of the standalone display.",
		onChange = function(setting, value) addon:SetBackgroundColor(value) end,
	},
	{
		key = "borderColor",
		type = "color",
		defaultValue = defaults.borderColor,
		label = "Border color",
		tooltip = "Sets the border color of the standalone display.",
		onChange = function(setting, value) addon:SetBorderColor(value) end,
	},
}

-- slash command opens options frame
SLASH_SPEEDYGONZALES1 = "/speedy"
SlashCmdList["SPEEDYGONZALES"] = function(msg)
	msg = msg:trim()
	if msg:lower() == "config" then
		category:Open()
	elseif msg == "" then
		category:SetValue("shown", not db.shown)
	else
		print("|cffffff00SpeedyGonzales:|r Type '/speedy' to toggle the frame or '/speedy config' to open the configuration.")
	end
end

local function copyDefaults(src, dst)
	if not src then return {} end
	if not dst then dst = {} end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dst[k] = copyDefaults(v, dst[k])
		elseif type(v) ~= type(dst[k]) then
			dst[k] = v
		end
	end
	return dst
end

function addon:ADDON_LOADED(addon)
	if addon ~= "SpeedyGonzales" then return end
	self:UnregisterEvent("ADDON_LOADED")

	-- create options defaults if they do not exist
	SpeedyGonzalesDB = copyDefaults(defaults, SpeedyGonzalesDB)
	db = SpeedyGonzalesDB

	category:SetTable(db)
	category:RegisterSettings(options)
	category:NotifyUpdate()

	self:SetPosition()

	self.updateFrame:Show()
end

function addon:PLAYER_ENTERING_WORLD()
	if UnitInVehicle("player") then
		speeder = "vehicle"
	end
end

function addon:UNIT_ENTERED_VEHICLE()
	speeder = "vehicle"
end

function addon:UNIT_EXITED_VEHICLE()
	speeder = "player"
end

function addon:SetUnit(unit)
	selectedUnit = assert(FindValueInTableIf(unitData, function(e) return e.key == unit end), format("Invalid unit '%s'.", unit))
	self:FixWidth()
end

function addon:OnMouseUp()
	self:StopMovingOrSizing()
	local point, _, _, xOff, yOff = self:GetPoint()
	if point then
		local pos = db.pos
		pos.point = point
		pos.xOff = xOff
		pos.yOff = yOff
	end
end

function addon:SetPosition()
	local pos = db.pos
	self:SetPoint(pos.point, pos.xOff, pos.yOff)
end

function addon:SetVisibility()
	self:SetShown(db.shown)
end

function addon:SetLock()
	self:EnableMouse(not db.locked)
end

-- set width depending on displayed unit type
function addon:FixWidth()
	self:SetWidth(BASE_WIDTH + (selectedUnit.extraWidth or 0))
end

function addon:SetBackgroundColor(color)
	self:SetBackdropColor(color.r, color.g, color.b, color.a)
end

function addon:SetBorderColor(color)
	self:SetBackdropBorderColor(color.r, color.g, color.b, color.a)
end
