function section:addSwatches(title, options, default, callback)
	local selected = default
	local row = newRow(self, 44, "Frame", {Name = "Swatches"})
	local labelW = UDim2.new(1, -(#options * 26 + 28), 0, 16)
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 6), Size = labelW, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local nameLabel = newLabel({Text = selected or "", Position = UDim2.new(0, 12, 0, 22), Size = UDim2.new(1, -(#options * 26 + 28), 0, 14),
		TextSize = 10, TextColor3 = Theme.Muted, Parent = row})
	local holder = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, #options * 26 - 6, 0, 20), BackgroundTransparency = 1, Parent = row,
	}, {listLayout(6, Enum.FillDirection.Horizontal)})

	local buttons = {}
	local function render()
		for name, b in pairs(buttons) do
			b.stroke.Transparency = (name == selected) and 0 or 1
		end
		nameLabel.Text = selected or "Custom"
	end
	for i, opt in ipairs(options) do
		local btn = create("TextButton", {
			Size = UDim2.new(0, 20, 0, 20), BackgroundColor3 = opt.Color, BorderSizePixel = 0,
			Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = holder,
		}, {corner(10)})
		local st = create("UIStroke", {
			Color = Color3.fromRGB(150, 150, 165), Thickness = 2, Transparency = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn,
		})
		btn:SetAttribute("NoTheme", true) 
		st:SetAttribute("NoTheme", true)
		buttons[opt.Name] = {btn = btn, stroke = st}
		btn.MouseButton1Click:Connect(function()
			selected = opt.Name
			render()
			if callback then task.spawn(callback, opt.Name) end
		end)
	end
	render()
	local api = {Instance = row}
	function api:Set(name, silent) 
		selected = name
		render()
		if name and not silent and callback then task.spawn(callback, name) end
	end
	return api
end