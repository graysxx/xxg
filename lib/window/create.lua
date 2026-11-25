function library.new(title, subtitle, version)
	local guiName = "ProjectControlPanel"
	L.resetState()

	pcall(function()
		local old = game:GetService("CoreGui"):FindFirstChild(guiName)
		if old then old:Destroy() end
	end)
	pcall(function()
		local old = LocalPlayer.PlayerGui:FindFirstChild(guiName)
		if old then old:Destroy() end
	end)

	local screen = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local okParent = pcall(function() screen.Parent = game:GetService("CoreGui") end)
	if not okParent then
		screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local W, H = math.min(440, vp.X - 20), math.min(580, vp.Y - 20)

	-- Root
	local root = create("Frame", {
		Name = "Root",
		Position = UDim2.fromOffset(math.floor((vp.X - W) / 2), math.floor((vp.Y - H) / 2)),
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1,
		Parent = screen,
	})
	local main = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = root,
	}, {corner(14), stroke(), padding(10, 10, 10, 10)})
	local scale = create("UIScale", {Scale = 0, Parent = main})
	surface(main, 1)

	-- header card
	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 108),
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Parent = main,
	}, {corner(12), stroke(), padding(12, 10, 12, 10)})

	surface(header, 1)

	local icon = create("Frame", {
		Name = "Icon",
		Position = UDim2.new(0, 0, 0, 2),
		Size = UDim2.new(0, 36, 0, 36),
		BackgroundColor3 = Theme.Card,
		BorderSizePixel = 0,
		Parent = header,
	}, {corner(10), stroke()})
	for i = -1, 1 do
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, i * 5),
			Size = UDim2.new(0, 14, 0, 2),
			BackgroundColor3 = Theme.SubText,
			BorderSizePixel = 0,
			Parent = icon,
		}, {corner(1)})
	end

	local titleLabel = newLabel({
		Name = "Title", Text = title or "PROJECT",
		Position = UDim2.new(0, 46, 0, 2), Size = UDim2.new(1, -190, 0, 18),
		Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})
	local subLabel = newLabel({
		Name = "Subtitle", Text = subtitle or "Control Panel",
		Position = UDim2.new(0, 46, 0, 20), Size = UDim2.new(1, -190, 0, 16),
		TextSize = 11, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = header,
	})

	-- badge 
	local badge = newLabel({
		Name = "Version", Text = version or "v1.0.0",
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -92, 0, 7),
		Size = UDim2.new(0, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentSoft,
		TextColor3 = Theme.Accent, TextSize = 10, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Center, Parent = header,
	})
	corner(10).Parent = badge
	padding(8, 0, 8, 0).Parent = badge
	stroke(Theme.AccentLine).Parent = badge

	--minimize, maximize, close
	local controls = create("Frame", {
		Name = "Controls", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 15),
		Size = UDim2.new(0, 80, 0, 24), BackgroundTransparency = 1, ZIndex = 5, Parent = main,
	})
	local minBtn = windowButton(controls, 0, Theme.Card)
	local maxBtn = windowButton(controls, 28, Theme.Card)
	local closeBtn = windowButton(controls, 56, Theme.Red)

	create("Frame", { -- minimize
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 3), Size = UDim2.new(0, 10, 0, 2),
		BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = minBtn,
	}, {corner(1)})
	create("Frame", { -- maximize
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = maxBtn,
	}, {corner(2), create("UIStroke", {Color = Theme.SubText, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	for _, rot in ipairs({45, -45}) do -- close
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 2),
			Rotation = rot, BackgroundColor3 = Theme.SubText, BorderSizePixel = 0, Parent = closeBtn,
		}, {corner(1)})
	end

	create("Frame", {
		Name = "Divider", Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = header,
	})

	local tabs = create("ScrollingFrame", {
		Name = "Tabs", Position = UDim2.new(0, 0, 0, 54), Size = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X, CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = header,
	}, {
		padding(1, 0, 1, 0),
		create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
			FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	-- mini bar
	local mini = create("Frame", {
		Name = "Mini", Size = UDim2.new(1, 0, 0, MINI_BAR_H), BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0, Visible = false, Parent = main,
	}, {corner(12), stroke(), padding(10, 0, 10, 0)})
	surface(mini, 1)
	local miniAvatar = create("ImageLabel", {
		Position = UDim2.new(0, 0, 0.5, -16), Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = mini,
	}, {corner(16), stroke()})
	local miniName = newLabel({Text = "DisplayName", Position = UDim2.new(0, 42, 0.5, -16), Size = UDim2.new(0, 104, 0, 17),
		Font = Enum.Font.GothamBold, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd, Parent = mini})
	local miniDisplay = newLabel({Text = "@Username", Position = UDim2.new(0, 42, 0.5, 1), Size = UDim2.new(0, 104, 0, 15),
		TextSize = 10, TextColor3 = Theme.Muted, TextTruncate = Enum.TextTruncate.AtEnd, Parent = mini})
	local miniChips = create("Frame", {
		Name = "Chips", Position = UDim2.new(0, 156, 0, 0), Size = UDim2.new(1, -156 - 94, 1, 0),
		BackgroundTransparency = 1, Parent = mini,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6),
		FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center,
	})})
	local chips = {}
	local function textWidth(sample)
		local ok, size = pcall(function()
			return TextService:GetTextSize(sample, 12, Enum.Font.GothamBold, Vector2.new(1000, 20))
		end)
		return ok and math.ceil(size.X) or (#sample * 8)
	end
	-- chip = icon 
	local function addChip(key, iconName, iconColor, sample, order, visible)
		local width = CHIP_PAD * 2 + CHIP_ICON + CHIP_GAP + textWidth(sample)
		local chip = create("Frame", {
			Name = key, Size = UDim2.new(0, width, 0, 30), BackgroundColor3 = Theme.Card, BorderSizePixel = 0,
			LayoutOrder = order, Visible = visible, Parent = miniChips,
		}, {corner(8), stroke(Theme.Border, 0.4)})
		surface(chip, 0.5)
		makeIcon(iconName, chip, iconColor, CHIP_ICON).Position = UDim2.new(0, CHIP_PAD, 0.5, -CHIP_ICON / 2)
		local val = newLabel({Text = "--", Position = UDim2.new(0, CHIP_PAD + CHIP_ICON + CHIP_GAP, 0, 0),
			Size = UDim2.new(1, -(CHIP_PAD * 2 + CHIP_ICON + CHIP_GAP), 1, 0), TextSize = 12,
			Font = Enum.Font.GothamBold, Parent = chip})
		chips[key] = {frame = chip, value = val, width = width}
	end
	addChip("ping", "signal", Theme.Green, "999 ms", 1, true)
	addChip("fps", "chart", Theme.Accent, "999 FPS", 2, true)
	addChip("afk", "clock", Theme.Blue, "00:00:00", 3, false) 

	local body = create("Frame", {
		Name = "Body", Position = UDim2.new(0, 0, 0, 118), Size = UDim2.new(1, 0, 1, -118),
		BackgroundTransparency = 1, Parent = main,
	})

	local self = setmetatable({
		screen = screen, container = screen, root = root, main = main, scale = scale,
		header = header, tabs = tabs, body = body, badge = badge, titleLabel = titleLabel, subLabel = subLabel,
		controls = controls, mini = mini, miniAvatar = miniAvatar, miniName = miniName, miniDisplay = miniDisplay, chips = chips,
		pages = {}, focusedPage = nil, listening = false,
		shown = true, closing = false, state = "normal",
		normalSize = UDim2.fromOffset(W, H), normalPos = root.Position,
		_conns = {}, _hovers = {}, _handles = {}, _token = 0, _geoToken = 0,
	}, library)

	screen.Destroying:Connect(function()
		for _, c in ipairs(self._conns) do
			c:Disconnect()
		end
	end)

	-- window
	closeBtn.MouseButton1Click:Connect(function() task.spawn(function() self:Close() end) end)
	minBtn.MouseButton1Click:Connect(function() self:Minimize() end)
	maxBtn.MouseButton1Click:Connect(function() self:Maximize() end)

	-- header
	makeDraggable(self, header, root)
	makeDraggable(self, mini, root)

	-- 
	self.toasts = create("Frame", {
		Name = "Toasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.new(0, 300, 1, -18), BackgroundTransparency = 1, ZIndex = 50, Parent = screen,
	}, {create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center,
	})})

	-- resize
	local T, C = 6, 14
	local handleDefs = {
		{Vector2.new(0, 0), UDim2.new(0, 0, 0, C),  UDim2.new(0, T, 1, -2 * C), -1,  0},
		{Vector2.new(1, 0), UDim2.new(1, 0, 0, C),  UDim2.new(0, T, 1, -2 * C),  1,  0},
		{Vector2.new(0, 0), UDim2.new(0, C, 0, 0),  UDim2.new(1, -2 * C, 0, T),  0, -1},
		{Vector2.new(0, 1), UDim2.new(0, C, 1, 0),  UDim2.new(1, -2 * C, 0, T),  0,  1},
		{Vector2.new(0, 0), UDim2.new(0, 0, 0, 0),  UDim2.new(0, C, 0, C),      -1, -1},
		{Vector2.new(1, 0), UDim2.new(1, 0, 0, 0),  UDim2.new(0, C, 0, C),       1, -1},
		{Vector2.new(0, 1), UDim2.new(0, 0, 1, 0),  UDim2.new(0, C, 0, C),      -1,  1},
		{Vector2.new(1, 1), UDim2.new(1, 0, 1, 0),  UDim2.new(0, C, 0, C),       1,  1},
	}
	for _, def in ipairs(handleDefs) do
		local dx, dy = def[4], def[5]
		local h = create("TextButton", {
			Name = "ResizeHandle", AnchorPoint = def[1], Position = def[2], Size = def[3],
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = root,
		})
		table.insert(self._handles, h)
		h.InputBegan:Connect(function(input)
			if self.state ~= "normal" then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local m0 = input.Position
			local s0 = root.AbsoluteSize
			local p0 = root.Position
			local x0, y0 = p0.X.Offset, p0.Y.Offset
			local screenSize = screen.AbsoluteSize
			local maxW, maxH = math.min(1100, screenSize.X), math.min(900, screenSize.Y)
			local conn
			conn = UserInputService.InputChanged:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
					local d = i.Position - m0
					local w, hgt, x, y = s0.X, s0.Y, x0, y0
					if dx ~= 0 then
						w = math.clamp(s0.X + dx * d.X, MIN_W, maxW)
						if dx < 0 then x = x0 + (s0.X - w) end
					end
					if dy ~= 0 then
						hgt = math.clamp(s0.Y + dy * d.Y, MIN_H, maxH)
						if dy < 0 then y = y0 + (s0.Y - hgt) end
					end
					root.Size = UDim2.fromOffset(w, hgt)
					root.Position = UDim2.fromOffset(x, y)
				end
			end)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect()
				end
			end)
		end)
	end

	-- hover 
	self:connect(RunService.Heartbeat, function()
		self:_updateHover()
		local p = self.focusedPage
		if p and p._dirty and self.state ~= "minimized" then
			if p:_relayout() then p._dirty = false end
		end
	end)

	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:_applyResponsive() end)
	self:_applyResponsive()

	self:_animate(true)

	return self
end