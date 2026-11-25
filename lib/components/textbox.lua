function section:addTextBox(title, placeholder, callback)
	local row = newRow(self, 36, "Frame", {Name = "TextBox"})
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0.4, -12, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
	local box = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.6, -14, 0, 22),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = Theme.Text, PlaceholderText = placeholder or "", PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false, ClipsDescendants = true, Text = "", Parent = row,
	}, {corner(6), stroke(Theme.Border), padding(8, 0, 8, 0)})
	box.FocusLost:Connect(function(enter)
		if callback then task.spawn(callback, box.Text, enter) end
	end)
	local api = {Instance = row}
	function api:Get() return box.Text end
	function api:Set(t) box.Text = t or "" end
	return api
end