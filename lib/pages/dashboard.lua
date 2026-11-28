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
	-- components
	function page:addHeading(overline, title, subtitle)
		local f = create("Frame", {
			Name = "Heading", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y,
			BackgroundTransparency = 1, LayoutOrder = self:_next(), Parent = self.container,
		}, {listLayout(3)})
		newLabel({Text = string.upper(overline or ""), Size = UDim2.new(1, 0, 0, 14), TextSize = 10,
			Font = Enum.Font.GothamMedium, TextColor3 = Theme.Muted, LayoutOrder = 1, Parent = f})
		newLabel({Text = title or "", Size = UDim2.new(1, 0, 0, 26), Font = Enum.Font.GothamBold,
			TextSize = 18, LayoutOrder = 2, Parent = f})
		local sub = newLabel({Text = subtitle or "", Size = UDim2.new(1, 0, 0, 16), TextSize = 11,
			TextColor3 = Theme.Muted, LayoutOrder = 3, Parent = f})
		self:_register(f, true)
		return {Instance = f, Subtitle = sub}
	end

	-- defs: {{Key, Title, Color, Value, Status, StatusColor}
	function page:addStats(defs)
		local n = #defs
		local GAP, CELL_H = 10, 84
		local grid = create("Frame", {
			Name = "Stats", Size = UDim2.new(1, 0, 0, CELL_H), BackgroundTransparency = 1,
			LayoutOrder = self:_next(), Parent = self.container,
		})

		local result, cells = {}, {}
		for i, def in ipairs(defs) do
			local cell, pop, bg = popCard(grid, def.Key or def.Title)
			cells[i] = cell
			local inner = create("Frame", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = pop,
			}, {padding(12, 10, 12, 10)})

			local hasIcon = def.Icon ~= nil
			if hasIcon then
				makeIcon(def.Icon, inner, def.Color or Theme.Accent, 14).Position = UDim2.new(0, 0, 0, 1)
			else
				create("Frame", {
					Position = UDim2.new(0, 0, 0, 5), Size = UDim2.new(0, 6, 0, 6),
					BackgroundColor3 = def.Color or Theme.Accent, BorderSizePixel = 0, Parent = inner,
				}, {corner(3)})
			end
			newLabel({Text = def.Title, Position = UDim2.new(0, hasIcon and 20 or 12, 0, 0), Size = UDim2.new(1, hasIcon and -20 or -12, 0, 16),
				TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
			local value = newLabel({Text = def.Value or "--", Position = UDim2.new(0, 0, 0, 18),
				Size = UDim2.new(1, 0, 0, 28), Font = Enum.Font.GothamBold, TextSize = 21,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
			local status = newLabel({Text = def.Status or "", Position = UDim2.new(0, 0, 0, 48),
				Size = UDim2.new(1, 0, 0, 14), TextSize = 10, TextColor3 = def.StatusColor or Theme.Muted,
				TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})

			self.library:_registerHover(cell, bg, self, pop)
			result[def.Key or i] = {
				Instance = cell,
				Set = function(_, v, s, c)
					if v ~= nil then
						v = tostring(v)
						value.Text = v
						value.TextSize = (#v > 11) and 16 or 21 
					end
					if s ~= nil then status.Text = s end
					if c ~= nil then status.TextColor3 = c end
				end,
			}
		end

		local lastCols = 0
		local function arrange(w)
			local best = 1
			for c = 2, n do
				if (w - GAP * (c - 1)) / c >= 150 then best = c end
			end
			if best == lastCols then return end
			lastCols = best
			local rows = math.ceil(n / best)
			grid.Size = UDim2.new(1, 0, 0, rows * CELL_H + (rows - 1) * GAP)
			for i, cell in ipairs(cells) do
				local row, col = math.floor((i - 1) / best), (i - 1) % best
				local inRow = (row < rows - 1) and best or (n - (rows - 1) * best)
				cell.Size = UDim2.new(1 / inRow, -GAP * (inRow - 1) / inRow, 0, CELL_H)
				cell.Position = UDim2.new(col / inRow, col * GAP / inRow, 0, row * (CELL_H + GAP))
			end
		end
		table.insert(self._updaters, arrange)
		arrange(self.library:_width() - 38)
		self:_register(grid, true)
		return result
	end

	function page:addAccountCard(info)
		local card, pop, bg = popCard(self.container, "Account")
		local inner = create("Frame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = pop,
		}, {padding(14, 14, 14, 12)})

		local avatar = create("ImageLabel", {
			Size = UDim2.new(0, 44, 0, 44), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = inner,
		}, {corner(22), stroke()})
		task.spawn(function()
			local okThumb, url = pcall(Players.GetUserThumbnailAsync, Players, info.UserId,
				Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if okThumb and url then avatar.Image = url end
		end)

		makeIcon("user", inner, Theme.SubText, 12).Position = UDim2.new(0, 58, 0, 1)
		newLabel({Text = "ACCOUNT INFORMATION", Position = UDim2.new(0, 74, 0, 0), Size = UDim2.new(1, -74, 0, 14),
			TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
		newLabel({Text = info.DisplayName or "DisplayName", Position = UDim2.new(0, 58, 0, 14), Size = UDim2.new(1, -58, 0, 18),
			Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})
		newLabel({Text = "@" .. (info.Name or "Username"), Position = UDim2.new(0, 58, 0, 32),
			Size = UDim2.new(1, -58, 0, 14), TextSize = 11, TextColor3 = Theme.Muted,
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = inner})

		create("Frame", {Position = UDim2.new(0, 0, 0, 62), Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = inner})

		newLabel({Text = "USER ID", Position = UDim2.new(0, 0, 0, 74), Size = UDim2.new(0.5, 0, 0, 14),
			TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
		newLabel({Text = tostring(info.UserId or "0"), Position = UDim2.new(0, 0, 0, 90), Size = UDim2.new(0.5, 0, 0, 18),
			Font = Enum.Font.GothamBold, TextSize = 12, Parent = inner})
		newLabel({Text = "ACCOUNT STATUS", Position = UDim2.new(0.5, 0, 0, 74), Size = UDim2.new(0.5, 0, 0, 14),
			TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, Parent = inner})
		newLabel({Text = "• " .. (info.Status or "Active"), Position = UDim2.new(0.5, 0, 0, 90), Size = UDim2.new(0.5, 0, 0, 18),
			Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Green, Parent = inner})

		self.library:_registerHover(card, bg, self, pop)
		self:_register(card, false, 132)
		return card
	end

	function page:addNewsCard(title, items)
		local card, pop, bg = popCard(self.container, "News")
		local content = create("Frame", {
			Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = pop,
		}, {padding(12, 12, 12, 12), listLayout(8)})

		local head = create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0, Parent = content})
		makeIcon("news", head, Theme.Accent, 14).Position = UDim2.new(0, 0, 0.5, -7)
		newLabel({Text = title or "What's New", Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(0.6, -22, 1, 0), Font = Enum.Font.GothamBold, TextSize = 13, Parent = head})

		for i, item in ipairs(items or {}) do
			local isNews = (item.Kind == "news")
			local entry = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, LayoutOrder = i,
				BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = content,
			}, {corner(8), padding(10, 10, 10, 10), listLayout(5)})
			surface(entry, 0.5)

			local meta = create("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 1, Parent = entry},
				{listLayout(6, Enum.FillDirection.Horizontal)})
			local badge = newLabel({
				Text = string.upper(item.Kind or "update"), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 0, BackgroundColor3 = isNews and Theme.GreenSoft or Theme.AccentSoft,
				TextColor3 = isNews and Theme.Green or Theme.Accent, Font = Enum.Font.GothamMedium, TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = meta,
			})
			corner(5).Parent = badge
			padding(8, 0, 8, 0).Parent = badge
			newLabel({Text = item.Date or "", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
				TextSize = 11, TextColor3 = Theme.SubText, LayoutOrder = 2, Parent = meta})

			newLabel({Text = item.Title or "", Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold,
				TextSize = 13, LayoutOrder = 2, Parent = entry})
			newLabel({Text = item.Text or "", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top, TextSize = 11, TextColor3 = Theme.Muted, LayoutOrder = 3, Parent = entry})
		end

		self.library:_registerHover(card, bg, self, pop)
		self:_register(card, false, content)
		return card
	end

	function page:addVersionCard(info)
		local card, pop, bg = popCard(self.container, "Version")
		local content = create("Frame", {
			Name = "Content", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, BackgroundTransparency = 1, Parent = pop,
		}, {padding(12, 12, 12, 12), listLayout(6)})

		local head = create("Frame", {Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, LayoutOrder = 0, Parent = content})
		makeIcon("info", head, Theme.Accent, 14).Position = UDim2.new(0, 0, 0.5, -7)
		newLabel({Text = "Version", Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(1, -22, 1, 0),
			Font = Enum.Font.GothamBold, TextSize = 13, Parent = head})

		local function row(order, label, value, color)
			local r = surface(create("Frame", {
				Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
				LayoutOrder = order, Parent = content,
			}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
			newLabel({Text = label, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0),
				TextSize = 11, TextColor3 = Theme.Muted, Parent = r})
			return newLabel({Text = value, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0),
				Size = UDim2.new(0.5, -12, 1, 0), Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = color or Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = r})
		end
		row(1, "UI Version", info.Version or "-")
		row(2, "Last update", info.Updated or "-")
		local statusLabel = row(3, "Status", info.Status or "Not checked", info.StatusColor or Theme.Muted)

		self.library:_registerHover(card, bg, self, pop)
		self:_register(card, false, content)
		return {SetStatus = function(_, text, color)
			statusLabel.Text = text
			if color then statusLabel.TextColor3 = color end
		end}
	end
end