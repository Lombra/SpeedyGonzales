local floor = math.floor
local GetUnitSpeed = GetUnitSpeed
local IsFlying = IsFlying
local IsSwimming = IsSwimming
local IsFalling = IsFalling

local BASE_WIDTH = 80

local db, unit
local speeder = "player"

-- data for the various unit displays
local unitData = {
	percent = "%",
	yards = " yd/s",
	miles = " mph",
	kilometers = " km/h",
	meters = " m/s",
}

local unitWidth = {
	percent = -16,
	kilometers = 8,
}

local unitTransformations = {
	percent = function(n)
		return floor(n / 7 * 100 + 0.1)
	end,
	yards = function(n)
		return floor(n * 10 + 0.01) / 10
	end,
	miles = function(n)
		return floor(n / 1.76 * 36 + 0.01) / 10
	end,
	kilometers = function(n)
		return floor(n * 9.144 * 3.6 + 0.01) / 10
	end,
	meters = function(n)
		return floor(n * 9.144 + 0.01) / 10
	end,
}

local function transform(speed)
	return unitTransformations[db.units](speed)
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
local addon = CreateFrame("Frame", "SpeedyGonzalesFrame", UIParent)
addon:SetHeight(32)
addon:SetMovable(true)
addon:SetToplevel(true)
addon:SetBackdrop({
	bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	edgeSize = 14,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
})
addon:SetBackdropColor(0, 0, 0, 0.8)
addon:SetBackdropBorderColor(0.3, 0.3, 0.3)
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
			speed = transform(GetUnitSpeed(speeder))
		end
		addon.text:SetFormattedText("%d%s", speed, unit)
		dataobj.text = format("%d%s", speed, unit)
	end)
end

-- create font string for the actual speed text
addon.text = addon:CreateFontString()
addon.text:SetPoint("CENTER", addon)
addon.text:SetFontObject("GameFontHighlight")
addon.text:SetSpacing(2)

local optionsFrame = CreateFrame("Frame")
optionsFrame.name = "SpeedyGonzales"
InterfaceOptions_AddCategory(optionsFrame)

local title = optionsFrame:CreateFontString(nil, nil, "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetPoint("RIGHT", -16, 0)
title:SetJustifyH("LEFT")
title:SetJustifyV("TOP")
title:SetText(optionsFrame.name)
optionsFrame.title = title

local function onClick(self)
	local checked = self:GetChecked()
	PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
	db[self.setting] = checked
	if self.func then
		addon[self.func](addon)
	end
end

-- check buttons data
local options = {
	{
		text = "Show",
		setting = "shown",
		func = "SetVisibility",
	},
	{
		text = "Lock",
		setting = "locked",
		func = "SetLock",
	},
	{
		text = "Show top speed",
		setting = "showTopSpeed",
	},
}

optionsFrame.options = {}

for i, v in ipairs(options) do
	local button = CreateFrame("CheckButton", nil, optionsFrame, "OptionsBaseCheckButtonTemplate")
	button:SetPushedTextOffset(0, 0)
	button:SetScript("OnClick", onClick)
	if i == 1 then
		button:SetPoint("TOPLEFT", optionsFrame.title, "BOTTOMLEFT", -2, -16)
	else
		button:SetPoint("TOP", optionsFrame.options[i - 1], "BOTTOM", 0, -8)
	end
	button.text = button:CreateFontString(nil, nil, "GameFontHighlight")
	button.text:SetPoint("LEFT", button, "RIGHT", 0, 1)
	button.text:SetText(v.text)
	button.func = v.func
	button.setting = v.setting
	optionsFrame.options[i] = button
end

local values = {
	"percent",
	"yards",
	"miles",
	"kilometers",
	"meters",
}

local unitNames = {
	percent = "Percent",
	yards = "Yards per second",
	miles = "Miles per hour",
	kilometers = "Kilometers per hour",
	meters = "Meters per second",
}

local function onClick(self, unit)
	addon:SetUnit(unit)
end

local dropdown = CreateFrame("Frame", "SpeedyGonzalesUnitsMenu", optionsFrame, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", optionsFrame.options[#options], "BOTTOMLEFT", -13, -24)
dropdown.label = dropdown:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
dropdown.label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 16, 3)
dropdown.label:SetText("Units")
dropdown.initialize = function(self)
	for i, v in ipairs(values) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = unitNames[v]
		info.func = onClick
		info.arg1 = v
		info.checked = (v == db.units)
		UIDropDownMenu_AddButton(info)
	end
end
UIDropDownMenu_SetWidth(dropdown, 120)

-- slash command opens options frame
SLASH_SPEEDYGONZALES1 = "/speedy"
SlashCmdList["SPEEDYGONZALES"] = function(msg)
	msg = msg:trim()
	if msg:lower() == "config" then
		InterfaceOptionsFrame_OpenToCategory(optionsFrame)
	elseif msg == "" then
		db.shown = not db.shown
		optionsFrame.options[1]:SetChecked(db.shown)
		addon:SetVisibility()
	else
		print("|cffffff00SpeedyGonzales:|r Type '/speedy' to toggle the frame or '/speedy config' to open the configuration.")
	end
end

local defaults = {
	units = "percent",
	shown = true,
	locked = false,
	showTopSpeed = false,
	pos = {
		point = "CENTER",
		xOff = 0,
		yOff = -100
	}
}

function addon:ADDON_LOADED(addon)
	if addon ~= "SpeedyGonzales" then return end
	self:UnregisterEvent("ADDON_LOADED")
	
	-- create options defaults if they do not exist
	SpeedyGonzalesDB = SpeedyGonzalesDB or defaults
	db = SpeedyGonzalesDB
	
	for i, button in ipairs(optionsFrame.options) do
		button:SetChecked(db[button.setting])
	end
	
	self:SetUnit(db.units)
	self:SetPosition()
	self:FixWidth()
	for k, v in pairs(options) do
		if v.func then self[v.func](self) end
	end
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

function addon:SetUnit(selectedUnit)
	UIDropDownMenu_SetText(dropdown, unitNames[selectedUnit])
	db.units = selectedUnit
	unit = unitData[selectedUnit]
	self:FixWidth()
end

function addon:OnMouseUp()
	self:StopMovingOrSizing()
	local point, _, _, xOff, yOff = self:GetPoint()
	local pos = db.pos
	pos.point = point
	pos.xOff = xOff
	pos.yOff = yOff
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
	self:SetWidth(BASE_WIDTH + (unitWidth[db.units] or 0))
end