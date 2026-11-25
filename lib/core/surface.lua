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
		local Theme = L.Theme
		local create, corner, stroke = L.create, L.corner, L.stroke

		L.Surfaces, L.themeHooks, L.S = {}, {}, {alpha = 0}

		function L.resetState()
			table.clear(L.Surfaces)
			table.clear(L.themeHooks)
			L.S.alpha = 0
		end

		function L.surface(obj, factor)
			factor = factor or 1
			table.insert(L.Surfaces, {obj = obj, f = factor})
			obj.BackgroundTransparency = L.S.alpha * factor
			return obj
		end

		function L.colorKey(c)
			return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
		end

		-- Slider 
		function L.accentGradient()
			local a = Theme.Accent
			if 0.299 * a.R + 0.587 * a.G + 0.114 * a.B > 0.8 then
				return ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.62), a:Lerp(Color3.new(0, 0, 0), 0.38))
			end
			return ColorSequence.new(a:Lerp(Color3.new(0, 0, 0), 0.25), a:Lerp(Color3.new(1, 1, 1), 0.12))
		end

		function L.accentOutline()
			return Theme.Accent:Lerp(Color3.new(1, 1, 1), 0.35)
		end

		function L.panelBg(parent)
			return L.surface(create("Frame", {
				Name = "Bg", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0, ZIndex = 0, Parent = parent,
			}, {corner(12), stroke()}), 1)
		end
	end
end