function library:addPage(title)
	local p = page.new(self, title)
	table.insert(self.pages, p)
	p.button.MouseButton1Click:Connect(function()
		self:SelectPage(p)
	end)
	return p
end

function library:SelectPage(target)
	for _, p in ipairs(self.pages) do
		local active = (p == target)
		p.container.Visible = active
		p:_setActive(active)
	end
	self.focusedPage = target
	if target then target._dirty = true end
end

function page.new(lib, title)
	local button = create("TextButton", {
		Name = title,
		AutoButtonColor = false,
		Size = UDim2.new(0, 0, 0, 28),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.AccentSoft,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = title,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		LayoutOrder = #lib.pages + 1,
		Parent = lib.tabs,
	}, {
		corner(9), padding(12, 0, 12, 0),
		create("UIStroke", {
			Name = "Stroke", Color = Theme.AccentLine, Thickness = 1, Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
	})

	local container = create("ScrollingFrame", {
		Name = title,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Border,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = lib.body,
	}, {listLayout(10), padding(7, 7, 11, 7)})

	local self = setmetatable({
		library = lib, button = button, container = container, sections = {}, _order = 0,
		items = {}, flowItems = {}, columns = {}, cols = 0, _updaters = {}, _dirty = true, _active = false,
	}, page)

	-- hover navbar
	button.MouseEnter:Connect(function()
		if self._active then return end
		tween(button, {BackgroundTransparency = 0.55, TextColor3 = Theme.SubText}, 0.12)
		tween(button.Stroke, {Transparency = 0.6}, 0.12)
	end)
	button.MouseLeave:Connect(function()
		if self._active then return end
		tween(button, {BackgroundTransparency = 1, TextColor3 = Theme.Muted}, 0.12)
		tween(button.Stroke, {Transparency = 1}, 0.12)
	end)

	-- "Flow"
	self.flow = create("Frame", {
		Name = "Flow", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1,
		LayoutOrder = 1000000, Parent = container,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10),
		FillDirection = Enum.FillDirection.Horizontal,
	})})
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self._dirty = true end)
	self:_setColumns(1)
	return self
end

function page:_next()
	self._order = self._order + 1
	return self._order
end

function page:_setActive(active)
	self._active = active
	apply(self.button, {
		BackgroundTransparency = active and 0 or 1,
		TextColor3 = active and Theme.Accent or Theme.Muted,
	}, true)
	apply(self.button.Stroke, {Transparency = active and 0 or 1}, true)
end

function page:addSection(title)
	local s = section.new(self, title)
	table.insert(self.sections, s)
	return s
end