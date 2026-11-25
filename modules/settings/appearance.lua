return {order = 20, build = function(ctx, tab)
	local UI, S = ctx.UI, ctx.settings
	local section = tab:addSection("Appearance")

	local options = {}
	for _, name in ipairs(UI.ThemeOrder) do
		table.insert(options, {Name = name, Color = UI.ThemePresets[name].Accent})
	end
	local picker
	local swatches = section:addSwatches("Theme", options, S.theme, function(name)
		UI:setTheme(name)
		if picker then picker:Set(UI.ThemePresets[name].Accent, true) end
	end)
	picker = section:addColorPicker("Custom Color", UI.ThemePresets[S.theme].Accent, function(color)
		UI:setCustomTheme(color)
		swatches:Set(nil, true) 
	end)
	local bgSlider = section:addSlider("Background Transparency", S.transparency, 0, 90, function(v)
		UI:setBackgroundTransparency(v / 100)
	end, "%")

	table.insert(S.resetters, function()
		swatches:Set(S.theme)
		picker:Set(UI.ThemePresets[S.theme].Accent, true)
		bgSlider:Set(S.transparency)
	end)
end}