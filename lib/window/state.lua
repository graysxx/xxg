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