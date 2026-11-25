return function(L)
	local create, panelBg = L.create, L.panelBg

	L.AUTO_Y = Enum.AutomaticSize.Y
	L.HOVER_SCALE = 1.03
	L.MIN_W, L.MIN_H = 320, 260
	L.MINI_BAR_H = 48
	L.MINIMIZED_H = L.MINI_BAR_H + 20
	L.CHIP_PAD, L.CHIP_ICON, L.CHIP_GAP = 8, 14, 6

	-- slot; pop card
	function L.popCard(parent, name)
		local slot = create("Frame", {
			Name = name or "Card", Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = parent,
		})
		local pop = create("Frame", {
			Name = "Pop", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = slot,
		})
		create("UIScale", {Scale = 1, Parent = pop})
		local bg = panelBg(pop)
		return slot, pop, bg
	end
end