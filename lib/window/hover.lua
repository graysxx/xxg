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

	function library:_registerHover(card, bg, pg, pop)
		table.insert(self._hovers, {
			card = card, bg = bg, stroke = bg:FindFirstChildOfClass("UIStroke"), page = pg,
			scale = pop and pop:FindFirstChildOfClass("UIScale"), hot = false,
		})
	end

	local function setHover(h, hot)
		local quad = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		if h.scale then
			local ti = hot and TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out) or quad
			TweenService:Create(h.scale, ti, {Scale = hot and HOVER_SCALE or 1}):Play()
		end
		TweenService:Create(h.bg, quad, {BackgroundColor3 = hot and Theme.PanelHover or Theme.Panel}):Play()
		if h.stroke then TweenService:Create(h.stroke, quad, {Color = hot and Theme.AccentLine or Theme.Border}):Play() end
	end

	function library:_updateHover()
		local active = self.shown and not self.closing and self.state ~= "minimized" and self.scale.Scale > 0.95
		local m = UserInputService:GetMouseLocation()
		for _, h in ipairs(self._hovers) do
			local inside = false
			if active and h.page == self.focusedPage and h.card.Parent then
				local c = h.page.container
				local cp, cs = c.AbsolutePosition, c.AbsoluteSize
				if m.X >= cp.X and m.X <= cp.X + cs.X and m.Y >= cp.Y and m.Y <= cp.Y + cs.Y then
					local p, s = h.card.AbsolutePosition, h.card.AbsoluteSize
					inside = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
				end
			end
			if inside ~= h.hot then
				h.hot = inside
				setHover(h, inside)
			end
		end
	end
end