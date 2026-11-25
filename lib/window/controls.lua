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

	function library:_refreshCanvas()
		for _, p in ipairs(self.pages) do
			p.container.AutomaticCanvasSize = Enum.AutomaticSize.None
			p.container.AutomaticCanvasSize = Enum.AutomaticSize.Y
			p._dirty = true
		end
	end

	function library:_width()
		return self.root.Size.X.Offset
	end

	function library:_applyResponsive()
		local compact = self.root.AbsoluteSize.X < 400
		self.badge.Visible = not compact
		local reserve = compact and 140 or 190
		self.titleLabel.Size = UDim2.new(1, -reserve, 0, 18)
		self.subLabel.Size = UDim2.new(1, -reserve, 0, 16)
	end

	function library:_animate(show)
		self._token = self._token + 1
		local token = self._token
		if show then
			self.root.Visible = true
			local tw = TweenService:Create(self.scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
			tw.Completed:Connect(function()
				if token == self._token then self:_refreshCanvas() end
			end)
			tw:Play()
			return tw
		else
			local tw = TweenService:Create(self.scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
			tw.Completed:Connect(function()
				if token == self._token then self.root.Visible = false end
			end)
			tw:Play()
			return tw
		end
	end

	function library:toggle()
		if self.closing then return end
		self.shown = not self.shown
		self:_animate(self.shown)
	end

	function library:Close()
		if self.closing then return end
		self.closing = true
		self.shown = false
		local tw = self:_animate(false)
		tw.Completed:Wait()
		if self.OnClose then
			pcall(self.OnClose)
		end
		if self.screen.Parent then
			self.screen:Destroy()
		end
	end

	function library:Destroy()
		self:Close()
	end

	function library:_setHandles(visible)
		for _, h in ipairs(self._handles) do
			h.Visible = visible
		end
	end

	function library:_saveGeometry()
		self.normalSize = UDim2.fromOffset(self.root.AbsoluteSize.X, self.root.AbsoluteSize.Y)
		self.normalPos = self.root.Position
	end

	function library:_goTo(size, pos)
		local tw = TweenService:Create(self.root, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = size, Position = pos})
		tw:Play()
		return tw
	end

	function library:_setMiniMode(on)
		self.header.Visible = not on
		self.mini.Visible = on
		self.body.Visible = not on
		self.controls.Position = on and UDim2.new(1, -10, 0, 12) or UDim2.new(1, -12, 0, 15)
	end
end