function section:addDropdown(title, list, callback)
	list = list or {}
	local ITEM_H, MAX_VISIBLE = 28, 3
	local open, count = false, 0

	local holder = create("Frame", {
		Name = "Dropdown", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1,
		ClipsDescendants = true, LayoutOrder = (function() self._order = self._order + 1 return self._order end)(),
		Parent = self.container,
	})

	local head = create("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)})
	surface(head, 0.5)
	local box = create("TextBox", {
		Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -44, 1, 0), BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text, PlaceholderText = title,
		PlaceholderColor3 = Theme.Muted, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = true,
		Text = "", Parent = head,
	})
	local arrow = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Theme.Muted, Rotation = 90, Parent = head,
	})
	local listFrame = create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4), padding(4, 4, 4, 4), listLayout(2)})

	local function relayout()
		local rows = math.min(count, MAX_VISIBLE)
		local h = rows > 0 and (rows * (ITEM_H + 2) + 6) or 0
		listFrame.Size = UDim2.new(1, 0, 0, h)
		listFrame.Visible = open and rows > 0
		tween(holder, {Size = UDim2.new(1, 0, 0, open and (40 + h) or 36)}, 0.2)
		tween(arrow, {Rotation = open and 270 or 90}, 0.2)
	end

	local function rebuild(filter)
		filter = (filter or ""):lower()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
		for _, value in ipairs(list) do
			if filter == "" or tostring(value):lower():find(filter, 1, true) then
				count = count + 1
				local item = create("TextButton", {
					Size = UDim2.new(1, -6, 0, ITEM_H), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
					AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
					TextXAlignment = Enum.TextXAlignment.Left, Text = tostring(value), LayoutOrder = count, Parent = listFrame,
				}, {corner(6), padding(10, 0, 0, 0)})
				item.MouseEnter:Connect(function() tween(item, {BackgroundColor3 = Theme.AccentSoft}) end)
				item.MouseLeave:Connect(function() tween(item, {BackgroundColor3 = Theme.Panel}) end)
				item.MouseButton1Click:Connect(function()
					box.Text = tostring(value)
					open = false
					relayout()
					if callback then
						task.spawn(callback, value, function(t) box.Text = t end)
					end
				end)
			end
		end
		relayout()
	end

	box.Focused:Connect(function()
		open = true
		rebuild("")
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if box:IsFocused() then rebuild(box.Text) end
	end)
	arrow.MouseButton1Click:Connect(function()
		open = not open
		if open then rebuild("") else relayout() end
	end)

	local api = {Instance = holder}
	function api:Set(text) 
		box.Text = text or ""
	end
	function api:Get() return box.Text end
	function api:Refresh() 
		open = false
		box:ReleaseFocus()
		for _, c in ipairs(listFrame:GetChildren()) do
			if c:IsA("TextButton") then c:Destroy() end
		end
		count = 0
		rebuild("")
	end
	return api
end