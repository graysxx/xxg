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

	function library:Minimize()
		if self.closing then return end
		self._geoToken = self._geoToken + 1

		if self.state == "minimized" then 
			self.state = "normal"
			self:_setMiniMode(false)
			self:_goTo(self.normalSize, self.normalPos)
			self:_setHandles(true)
			return
		end

		if self.state == "normal" then self:_saveGeometry() end
		self.state = "minimized"
		self:_setMiniMode(true)
		self:_setHandles(false)
		self:_resizeMini(self.normalPos)
	end

	function library:Maximize()
		if self.closing then return end
		self._geoToken = self._geoToken + 1

		if self.state == "maximized" then 
			self.state = "normal"
			self:_goTo(self.normalSize, self.normalPos)
			self:_setHandles(true)
			return
		end

		if self.state == "normal" then self:_saveGeometry() end
		self.state = "maximized"
		self:_setMiniMode(false)
		self:_setHandles(false)
		local vp = self.screen.AbsoluteSize
		local w, h = math.min(vp.X - 40, 1000), math.min(vp.Y - 40, 760)
		self:_goTo(UDim2.fromOffset(w, h), UDim2.fromOffset(math.floor((vp.X - w) / 2), math.floor((vp.Y - h) / 2)))
	end
end