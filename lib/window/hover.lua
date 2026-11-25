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