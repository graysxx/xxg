function section.new(pg, title)
	local card, pop, bg = popCard(pg.container, title)
	local content = create("Frame", {
		Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
		BackgroundTransparency = 1, Parent = pop,
	}, {padding(12, 12, 12, 12), listLayout(6)})

	newLabel({Name = "Title", Text = string.upper(title), Size = UDim2.new(1, 0, 0, 18),
		Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Muted, LayoutOrder = 0, Parent = content})

	pg.library:_registerHover(card, bg, pg, pop)
	pg:_register(card, false, content)
	return setmetatable({page = pg, library = pg.library, container = content, card = card, _order = 0}, section)
end

local function newRow(sec, height, className, extra)
	sec._order = sec._order + 1
	local props = {
		Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
		LayoutOrder = sec._order, Parent = sec.container,
	}
	for k, v in pairs(extra or {}) do
		props[k] = v
	end
	return surface(create(className or "Frame", props, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
	L.newRow = newRow
end

function section:addLabel(text)
	self._order = self._order + 1
	return newLabel({
		Text = text, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11, TextColor3 = Theme.Muted,
		LayoutOrder = self._order, Parent = self.container,
	})
	L.newRow = newRow
end

function section:addInfo(title, value)
	local row = newRow(self, 36, "Frame", {Name = "Info"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local val = newLabel({Text = value or "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.5, -12, 1, 0), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = row})
	return {Instance = row, Set = function(_, text, color)
		val.Text = tostring(text)
		if color then val.TextColor3 = color end
	end}
	L.newRow = newRow
end