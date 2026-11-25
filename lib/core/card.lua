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
		local create, panelBg = L.create, L.panelBg

		L.AUTO_Y = Enum.AutomaticSize.Y
		L.HOVER_SCALE = 1.03
		L.MIN_W, L.MIN_H = 320, 260
		L.MINI_BAR_H = 48
		L.MINIMIZED_H = L.MINI_BAR_H + 20
		L.CHIP_PAD, L.CHIP_ICON, L.CHIP_GAP = 8, 14, 6

		-- slot; pop card
		function L.popCard(parent, name)
			local slot = create("Frame", {
				Name = name or "Card", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = parent,
			})
			local pop = create("Frame", {
				Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = slot,
			})
			create("UIScale", {Scale = 1, Parent = pop})
			local bg = panelBg(pop)
			return slot, pop, bg
		end
	end
end