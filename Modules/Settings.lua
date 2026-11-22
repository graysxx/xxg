return function(ctx)
	local UI, Theme, Cfg = ctx.UI, ctx.Theme, ctx.Cfg
	local D = Cfg.Defaults or {}
	local defaultTheme = UI.ThemePresets[D.Theme] and D.Theme or "White"
	local defaultTransparency = D.Transparency or 40
	local defaultLanguage = D.Language or "English"
	local defaultKey = D.ToggleKey or Enum.KeyCode.RightBracket

	local page = UI:addPage("Settings")
	ctx.pages.Settings = page

	-- keybind
	local keybindSection = page:addSection("Keybinds")
	local kbPanel = keybindSection:addKeybind("Toggle Panel", defaultKey, function()
		UI:toggle()
	end, nil, true) -- true = keybind notifies when pressed

	-- appearance
	local appearanceSection = page:addSection("Appearance")
	local themeOptions = {}
	for _, name in ipairs(UI.ThemeOrder) do
		table.insert(themeOptions, {Name = name, Color = UI.ThemePresets[name].Accent})
	end
	local customPicker
	local themeSwatches = appearanceSection:addSwatches("Theme", themeOptions, defaultTheme, function(name)
		UI:setTheme(name)
		if customPicker then customPicker:Set(UI.ThemePresets[name].Accent, true) end
	end)

	customPicker = appearanceSection:addColorPicker("Custom Color", UI.ThemePresets[defaultTheme].Accent, function(color)
		UI:setCustomTheme(color)
		themeSwatches:Set(nil, true) 
	end)
	local bgSlider = appearanceSection:addSlider("Background Transparency", defaultTransparency, 0, 90, function(v)
		UI:setBackgroundTransparency(v / 100)
	end, "%")

	-- language
	local languageSection = page:addSection("Language")
	local langDrop = languageSection:addDropdown("Language", UI.Languages, function(name)
		UI:setLanguage(name)
	end)
	langDrop:Set(defaultLanguage)

	-- discord
	if Cfg.Discord and Cfg.Discord.Code then
		local code = Cfg.Discord.Code
		local discordSection = page:addSection("Discord")
		discordSection:addButton(syn and "Join the Discord server" or "Copy Discord Link", function()
			if syn then
				syn.request({
					Url = "http://127.0.0.1:6463/rpc?v=1",
					Method = "POST",
					Headers = {
						["Content-Type"] = "application/json",
						["Origin"] = "https://discord.com"
					},
					Body = game:GetService("HttpService"):JSONEncode({
						cmd = "INVITE_BROWSER",
						args = {code = code},
						nonce = game:GetService("HttpService"):GenerateGUID(false)
					}),
				})
				UI:notify("Discord invite sent", "success")
				return
			end
			local okCopy = pcall(setclipboard, "https://www.discord.com/invite/" .. code)
			if okCopy then
				UI:notify("Discord link copied", "success")
			else
				UI:notify("Failed to copy Discord link", "error")
			end
		end)
	end

	-- reset
	local resetSection = page:addSection("Reset")
	resetSection:addButton("Reset Settings", function()
		kbPanel:Set(defaultKey)
		themeSwatches:Set(defaultTheme)    
		customPicker:Set(UI.ThemePresets[defaultTheme].Accent, true)
		bgSlider:Set(defaultTransparency)
		langDrop:Set(defaultLanguage)
		UI:setLanguage(defaultLanguage)
		UI:notify("Settings reset", "success")
	end)
	resetSection:addLabel("Resets keybinds, color theme, and background transparency to their defaults.")
end