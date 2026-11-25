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

	return function(L)
		local library = L.library
		local langLookup, langHooks, currentLang = {}, {}, "en"
		local entries, nameToCode = {}, {}
		library.Languages = {}

		local function indexText(t, entry)
			if type(t) ~= "string" then return end
			langLookup[t] = langLookup[t] or {e = entry, up = false}
			local u = string.upper(t)
			langLookup[u] = langLookup[u] or {e = entry, up = true}
		end

		function library:registerLanguage(code, name, strings)
			if not nameToCode[name] then table.insert(library.Languages, name) end
			nameToCode[name] = code
			for _, t in ipairs(strings or {}) do
				local en, tr = t[1], t[2]
				if type(en) == "string" and type(tr) == "string" then
					local e = entries[en] or {en = en}
					entries[en] = e
					e[code] = tr
					indexText(en, e)
					indexText(tr, e)
				end
			end
		end

		function library:tr(text)
			if type(text) ~= "string" then return text end
			local hit = langLookup[text]
			if not hit then return text end
			local out = hit.e[currentLang] or hit.e.en or text
			return hit.up and string.upper(out) or out
		end

		function library:getLanguage() return currentLang end
		function library:onLanguage(fn) table.insert(langHooks, fn) end

		function library:setLanguage(name)
			local code = nameToCode[name]
			if not code then return end
			currentLang = code
			for _, obj in ipairs(self.screen:GetDescendants()) do
				if obj:IsA("TextLabel") or obj:IsA("TextButton") then
					local t = self:tr(obj.Text)
					if t ~= obj.Text then obj.Text = t end
				elseif obj:IsA("TextBox") then
					local t = self:tr(obj.PlaceholderText)
					if t ~= obj.PlaceholderText then obj.PlaceholderText = t end
				end
			end
			for _, hook in ipairs(langHooks) do pcall(hook, code) end
		end
	end
end