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
	end

	function section:addLabel(text)
		self._order = self._order + 1
		return newLabel({
			Text = text, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11, TextColor3 = Theme.Muted,
			LayoutOrder = self._order, Parent = self.container,
		})
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
	end
	L.newRow = newRow
end