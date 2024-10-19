local _, Speedy = ...

local SettingsColorSwatchMixin = CreateFromMixins(DefaultTooltipMixin)

function SettingsColorSwatchMixin:OnLoad()
	DefaultTooltipMixin.OnLoad(self)
end

function SettingsColorSwatchMixin:Init(value, initTooltip)
	self:SetValue(value)
	self:SetTooltipFunc(initTooltip)
end

function SettingsColorSwatchMixin:SetValue(value)
	self.Texture:SetVertexColor(value.r, value.g, value.b, value.a)
end

local function createColorSwatch(parent)
	local colorSwatch = CreateFrame("Button", nil, parent)
	Mixin(colorSwatch, SettingsColorSwatchMixin)
	colorSwatch:OnLoad()
	colorSwatch:SetSize(30, 29)
	colorSwatch:SetPoint("LEFT", parent, "CENTER", -80, 0)
	colorSwatch:SetNormalAtlas("checkbox-minimal")

	colorSwatch.Texture = colorSwatch:CreateTexture(nil, "ARTWORK", nil, 1)
	colorSwatch.Texture:SetTexture([[Interface\Common\common-iconmask]])
	colorSwatch.Texture:SetPoint("TOPRIGHT", -6, -6)
	colorSwatch.Texture:SetPoint("BOTTOMLEFT", 6.5, 6)

	colorSwatch.HoverBackground = colorSwatch:CreateTexture(nil, "BACKGROUND")

	return colorSwatch
end

SpeedyGonzalesSettingsColorSwatchControlMixin = CreateFromMixins(SettingsControlMixin);

function SpeedyGonzalesSettingsColorSwatchControlMixin:OnLoad()
	SettingsControlMixin.OnLoad(self)

	self.ColorSwatch = createColorSwatch(self)

	self.ColorSwatch:SetScript("OnClick", function()
		local currentValue = self:GetSetting():GetValue()

		local info = {
			swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				local a = ColorPickerFrame:GetColorAlpha()
				self:GetSetting():SetValue({ r = r, g = g, b = b, a = a })
			end,
			cancelFunc = function(previousValues)
				self:GetSetting():SetValue(previousValues)
			end,
			hasOpacity = true,
			r = currentValue.r,
			g = currentValue.g,
			b = currentValue.b,
			opacity = currentValue.a,
		}

		ColorPickerFrame:SetupColorPickerAndShow(info)
	end)

	self.Tooltip:SetScript("OnMouseUp", function()
		if self.ColorSwatch:IsEnabled() then
			self.ColorSwatch:Click()
		end
	end)
end

function SpeedyGonzalesSettingsColorSwatchControlMixin:Init(initializer)
	SettingsControlMixin.Init(self, initializer)

	local setting = self:GetSetting()
	local options = initializer:GetOptions()
	local initTooltip = Settings.CreateOptionsInitTooltip(setting, initializer:GetName(), initializer:GetTooltip(), options)

	self.ColorSwatch:Init(setting:GetValue(), initTooltip)
end

function SpeedyGonzalesSettingsColorSwatchControlMixin:OnSettingValueChanged(setting, value)
	SettingsControlMixin.OnSettingValueChanged(self, setting, value)
    self.ColorSwatch:SetValue(value)
end

function SpeedyGonzalesSettingsColorSwatchControlMixin:Release()
	self.ColorSwatch:SetScript("OnClick", nil)
	SettingsControlMixin.Release(self)
end

local function CreateColorSettingInitializer(setting, options, tooltip)
	assert(setting:GetVariableType() == "table")
	return Settings.CreateControlInitializer("SpeedyGonzalesSettingsColorSwatchControlTemplate", setting, nil, tooltip)
end

local function AddInitializerToLayout(category, initializer)
	local layout = SettingsPanel:GetLayout(category)
	layout:AddInitializer(initializer)
end

local function CreateColorSetting(category, setting, info)
	local initializer = CreateColorSettingInitializer(setting, nil, info.tooltip)
	AddInitializerToLayout(category, initializer)
	return initializer
end

Speedy.AddSettingControlType("color", {
	func = CreateColorSetting,
	backingType = "table",
})
