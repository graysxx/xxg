function library:notify(text, kind)
	if self.closing then return end
	kind = kind or "success"
	text = self:tr(text)
	self._toastId = (self._toastId or 0) + 1

	local slot = create("Frame", {
		Name = "Slot", Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1,
		LayoutOrder = self._toastId, Parent = self.toasts,
	})
	local card = create("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -22), Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, GroupTransparency = 1, Parent = slot,
	}, {corner(12), stroke(Theme.Border)})

	local tint, soft, iconName
	if kind == "error" then
		tint, soft, iconName = Theme.Red, Color3.fromRGB(76, 28, 28), "cross"
	elseif kind == "info" then
		tint, soft, iconName = Theme.Accent, Theme.AccentSoft, "info"
	else
		tint, soft, iconName = Theme.Green, Theme.GreenSoft, "check"
	end
	local tile = create("Frame", {
		Position = UDim2.new(0, 10, 0.5, -13), Size = UDim2.new(0, 26, 0, 26),
		BackgroundColor3 = soft, BorderSizePixel = 0, Parent = card,
	}, {corner(13)})
	makeIcon(iconName, tile, tint, 14).Position = UDim2.new(0.5, -7, 0.5, -7)
	newLabel({Text = text, Position = UDim2.new(0, 46, 0, 0), Size = UDim2.new(1, -58, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card})

	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 0, 0), GroupTransparency = 0}):Play()
	task.delay(2.4, function()
		if not card.Parent then return end
		local tw = TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Position = UDim2.new(0.5, 0, 0, -16), GroupTransparency = 1})
		tw.Completed:Connect(function() slot:Destroy() end)
		tw:Play()
	end)
end