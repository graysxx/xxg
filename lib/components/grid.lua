function section:addGrid(height, cellW, cellH, fill)
	cellW, cellH = cellW or 84, cellH or 104
	local baseHeight = height or 220
	local row = newRow(self, baseHeight, "Frame", {Name = "Grid", ClipsDescendants = true})
	local scroll = create("ScrollingFrame", {
		Position = UDim2.new(0, 6, 0, 6), Size = UDim2.new(1, -12, 1, -12), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y, Parent = row,
	}, {create("UIGridLayout", {
		CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})})
	local status = newLabel({
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, -24, 0, 40),
		TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center,
		Visible = false, ZIndex = 3, Parent = row,
	})

	if fill ~= false and self.card then
		for _, it in ipairs(self.page.items) do
			if it.frame == self.card then
				it.grow = function(extra) row.Size = UDim2.new(1, 0, 0, baseHeight + extra) end
			end
		end
	end

	local lib = self.library
	local count = 0
	local api = {Instance = row}

	function api:Clear()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
	end

	function api:SetStatus(text)
		text = text or ""
		status.Text = lib:tr(text)
		status.Visible = text ~= ""
	end

	function api:Add(image, text, onClick, fav)
		count = count + 1
		local cell = create("TextButton", {
			Name = "Cell", AutoButtonColor = false, Text = "", BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0, LayoutOrder = count, Parent = scroll,
		}, {corner(8), stroke(Theme.Border, 0.4)})
		local img = create("ImageLabel", {
			BackgroundTransparency = 1, Position = UDim2.new(0.5, -30, 0, 6), Size = UDim2.fromOffset(60, 60),
			Image = image or "", ScaleType = Enum.ScaleType.Fit, Parent = cell,
		})
		newLabel({
			Text = text or "", Position = UDim2.new(0, 4, 0, 68), Size = UDim2.new(1, -8, 0, cellH - 72),
			TextSize = 10, TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top, Parent = cell,
		})
		cell.MouseEnter:Connect(function() tween(cell, {BackgroundColor3 = Theme.AccentSoft}) end)
		cell.MouseLeave:Connect(function() tween(cell, {BackgroundColor3 = Theme.Panel}) end)
		cell.MouseButton1Click:Connect(function()
			if onClick then task.spawn(onClick) end
		end)

		local paint
		if fav then
			local on = fav.on and true or false
			local btn = create("TextButton", {
				Name = "Fav", AutoButtonColor = false, BackgroundTransparency = 1, Text = "★",
				Font = Enum.Font.GothamBold, TextSize = 17, Position = UDim2.new(1, -24, 0, 2),
				Size = UDim2.fromOffset(22, 22), ZIndex = 3, Parent = cell,
			})
			btn:SetAttribute("NoTheme", true) 
			paint = function(state)
				if not cell.Parent then return false end 
				on = state and true or false
				btn.Text = on and "★" or "☆"
				btn.TextColor3 = on and Color3.fromRGB(251, 191, 36) or Theme.Muted
				return true
			end
			paint(on)
			btn.MouseButton1Click:Connect(function()
				paint(not on)
				if fav.onToggle then task.spawn(fav.onToggle, on) end
			end)
		end
		return img, paint
	end

	return api
end