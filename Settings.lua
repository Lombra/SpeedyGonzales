local _, Speedy = ...

local settingControls = {
	[Settings.VarType.Boolean] = {
		func = function(category, setting, info)
			Settings.CreateCheckbox(category, setting, info.tooltip)
		end
	},

	[Settings.VarType.String] = {
		func = function(category, setting, info)
			local options = info.options
			if type(options) == "table" then
				function options()
					local container = Settings.CreateControlTextContainer()
					for i, option in ipairs(info.options) do
						container:Add(option.key, option.label)
					end
					return container:GetData()
				end
			end
			Settings.CreateDropdown(category, setting, options, info.tooltip)
		end
	},
}

local CategoryMixin = { }

local function CreateCategory(name, category)
	local settingsCategory = {
		name = name,
		category = category,
		settings = { },
	}
	Mixin(settingsCategory, CategoryMixin)
	return settingsCategory
end

local function RegisterCategory(name)
	local category, layout = Settings.RegisterVerticalLayoutCategory(name)
	Settings.RegisterAddOnCategory(category)
	return CreateCategory(name, category)
end

function CategoryMixin:SetTable(tbl)
	self.table = tbl
end

function CategoryMixin:Open()
	Settings.OpenToCategory(self.category:GetID())
end

function CategoryMixin:RegisterSettings(tbl)
	for i, v in ipairs(tbl) do
		self:RegisterSetting(v)
	end
end

function CategoryMixin:RegisterSetting(info)
	local settingControl = assert(settingControls[info.type], format("Unknown setting type '%s'.", info.type))

	local variable = self:GetVariable(info.key)
	local setting = Settings.RegisterAddOnSetting(self.category, variable, info.key, self.table, settingControl.backingType or info.type, info.label, info.defaultValue)
	settingControl.func(self.category, setting, info)

	if type(info.onChange) == "function" then
		setting:SetValueChangedCallback(info.onChange)
	end

	table.insert(self.settings, setting)
end

function CategoryMixin:GetVariable(key)
	return format("%s.%s", self.name, key)
end

function CategoryMixin:SetValue(key, value)
	Settings.SetValue(self:GetVariable(key), value)
end

function CategoryMixin:NotifyUpdate()
	for i, setting in ipairs(self.settings) do
		setting:NotifyUpdate()
	end
end

local function AddSettingControlType(name, func)
	settingControls[name] = func
end

Speedy.RegisterCategory = RegisterCategory
Speedy.AddSettingControlType = AddSettingControlType
