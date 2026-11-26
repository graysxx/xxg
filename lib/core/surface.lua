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