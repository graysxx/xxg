return function(L)
	local Players, UserInputService, TweenService, RunService, TextService = L.Players, L.UserInputService, L.TweenService, L.RunService, L.TextService
	local LocalPlayer = L.LocalPlayer
	local Theme, ThemePresets, ThemeOrder, THEME_KEYS = L.Theme, L.ThemePresets, L.ThemeOrder, L.THEME_KEYS
	local create, tween, apply, corner, stroke, padding, listLayout, newLabel = L.create, L.tween, L.apply, L.corner, L.stroke, L.padding, L.listLayout, L.newLabel
	local surface, colorKey, accentGradient, accentOutline, panelBg = L.surface, L.colorKey, L.accentGradient, L.accentOutline, L.panelBg
	local makeIcon, popCard, makeDraggable, windowButton = L.makeIcon, L.popCard, L.makeDraggable, L.windowButton
	local AUTO_Y, HOVER_SCALE = L.AUTO_Y, L.HOVER_SCALE
	local MIN_W, MIN_H, MINI_BAR_H, MINIMIZED_H = L.MIN_W, L.MIN_H, L.MINI_BAR_H, L.MINIMIZED_H
	local CHIP_PAD, CHIP_ICON, CHIP_GAP = L.CHIP_PAD, L.CHIP_ICON, L.CHIP_GAP
	local library, page, section = L.library, L.page, L.section
	local Surfaces, themeHooks, S = L.Surfaces, L.themeHooks, L.S
	local newRow = L.newRow

	local function isThemed(obj, stopAt)
		local p = obj
		while p and p ~= stopAt do
			if p:GetAttribute("NoTheme") then return false end
			p = p.Parent
		end
		return true
	end

	function library:setTheme(name)
		local preset = ThemePresets[name]
		if not preset then return end
		local map = {}
		for _, k in ipairs(THEME_KEYS) do
			if preset[k] then map[colorKey(Theme[k])] = preset[k] end
		end
		for _, k in ipairs(THEME_KEYS) do
			if preset[k] then Theme[k] = preset[k] end
		end

		local function remap(obj, prop)
			local ok, c = pcall(function() return obj[prop] end)
			if ok and typeof(c) == "Color3" then
				local new = map[colorKey(c)]
				if new then obj[prop] = new end
			end
		end
		for _, obj in ipairs(self.screen:GetDescendants()) do
			if isThemed(obj, self.screen) then
				if obj:IsA("UIStroke") then
					remap(obj, "Color")
				elseif obj:IsA("GuiObject") then
					remap(obj, "BackgroundColor3")
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then
						remap(obj, "TextColor3")
					elseif obj:IsA("TextBox") then
						remap(obj, "TextColor3")
						remap(obj, "PlaceholderColor3")
					end
					if obj:IsA("ScrollingFrame") then remap(obj, "ScrollBarImageColor3") end
				end
			end
		end
		for _, hook in ipairs(themeHooks) do pcall(hook) end
		self.themeName = name
	end

	function library:setCustomTheme(color)
		local taken = {}
		for _, k in ipairs({"Background", "Panel", "PanelHover", "Card", "Border", "TrackOff", "Text", "SubText", "Muted",
			"Green", "GreenSoft", "Orange", "Blue", "Red"}) do
			taken[colorKey(Theme[k])] = true
		end

		local function unique(c)
			for _ = 1, 8 do
				if not taken[colorKey(c)] then break end
				c = Color3.fromRGB(math.min(255, math.floor(c.R * 255 + 0.5) + 1), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
			end
			taken[colorKey(c)] = true
			return c
		end
		ThemePresets.Custom = {
			Accent = unique(color),
			AccentSoft = unique(color:Lerp(Theme.Background, 0.8)),
			AccentLine = unique(color:Lerp(Color3.new(0, 0, 0), 0.45)),
		}
		self:setTheme("Custom")
	end

	-- a = 0 
	function library:setBackgroundTransparency(a)
		a = math.clamp(a, 0, 1)
		S.alpha = a
		for _, sf in ipairs(Surfaces) do
			sf.obj.BackgroundTransparency = a * sf.f
		end
	end
end