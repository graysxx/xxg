function section:addColorPicker(title, default, callback)
	local lib = self.library
	local color = default or Theme.Accent
	local h, s, v = Color3.toHSV(color)
	local open = false
	local D, SQ, R_MID, THICK, N = 160, 84, 71, 14, 90
	local PANEL_H = 176

	self._order = self._order + 1
	local holder = create("Frame", {
		Name = "ColorPicker", Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ClipsDescendants = true,
		LayoutOrder = self._order, Parent = self.container,
	})
	local head = surface(create("Frame", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)
	newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -150, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd, Parent = head})
	local arrow = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.new(0, 24, 0, 24),
		BackgroundTransparency = 1, Text = ">", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Theme.Muted, Rotation = 90, Parent = head,
	})
	local hexBox = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0.5, 0), Size = UDim2.new(0, 74, 0, 22),
		BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = Theme.Text, ClearTextOnFocus = false, PlaceholderText = "#RRGGBB", PlaceholderColor3 = Theme.Muted,
		Text = "", Parent = head,
	}, {corner(6), stroke(Theme.Border)})
	local preview = create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -114, 0.5, 0), Size = UDim2.new(0, 18, 0, 18),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = head,
	}, {corner(9), stroke(Theme.Border)})
	preview:SetAttribute("NoTheme", true)

	local panel = surface(create("Frame", {
		Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, PANEL_H),
		BackgroundColor3 = Theme.Card, BorderSizePixel = 0, Parent = holder,
	}, {corner(8), stroke(Theme.Border, 0.4)}), 0.5)

	local wheel = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, D, 0, D),
		BackgroundTransparency = 1, Parent = panel,
	})
	wheel:SetAttribute("NoTheme", true)

	for i = 0, N - 1 do
		local ang = (i + 0.5) / N * 2 * math.pi
		create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, D / 2 + R_MID * math.cos(ang), 0, D / 2 + R_MID * math.sin(ang)),
			Size = UDim2.new(0, THICK, 0, 7), Rotation = math.deg(ang),
			BackgroundColor3 = Color3.fromHSV((i + 0.5) / N, 1, 1), BorderSizePixel = 0, Parent = wheel,
		})
	end

	local sq = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, D / 2, 0, D / 2), Size = UDim2.new(0, SQ, 0, SQ),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = wheel,
	}, {corner(5)})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sq,
	}, {corner(5), create("UIGradient", {Transparency = NumberSequence.new(0, 1)})})
	create("Frame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sq,
	}, {corner(5), create("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)})})

	local function marker()
		return create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(0, 14, 0, 14), BorderSizePixel = 0, ZIndex = 3, Parent = wheel,
		}, {corner(7), create("UIStroke", {Color = Color3.new(1, 1, 1), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})})
	end
	local hueMarker, svMarker = marker(), marker()

	local area = create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = wheel,
	})

	local function hexOf(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function render(exact)
		color = exact or Color3.fromHSV(h, s, v)
		sq.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		local ang = h * 2 * math.pi
		hueMarker.Position = UDim2.new(0, D / 2 + R_MID * math.cos(ang), 0, D / 2 + R_MID * math.sin(ang))
		hueMarker.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svMarker.Position = UDim2.new(0, D / 2 - SQ / 2 + s * SQ, 0, D / 2 - SQ / 2 + (1 - v) * SQ)
		svMarker.BackgroundColor3 = color
		preview.BackgroundColor3 = color
		hexBox.Text = hexOf(color)
	end

	local lastFire = 0
	local function fire(force)
		if not callback then return end
		local now = os.clock()
		if force or now - lastFire > 0.12 then 
			lastFire = now
			task.spawn(callback, color)
		end
	end

	local mode
	local function update(pos)
		local c = area.AbsolutePosition + area.AbsoluteSize / 2
		local dx, dy = pos.X - c.X, pos.Y - c.Y
		if mode == "hue" then
			h = (math.atan2(dy, dx) / (2 * math.pi)) % 1
		elseif mode == "sv" then
			s = math.clamp(dx / SQ + 0.5, 0, 1)
			v = 1 - math.clamp(dy / SQ + 0.5, 0, 1)
		end
		render()
		fire(false)
	end
	area.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local c = area.AbsolutePosition + area.AbsoluteSize / 2
			local dx, dy = input.Position.X - c.X, input.Position.Y - c.Y
			local dist = math.sqrt(dx * dx + dy * dy)
			if dist >= R_MID - THICK / 2 - 6 and dist <= R_MID + THICK / 2 + 6 then
				mode = "hue"
			elseif math.abs(dx) <= SQ / 2 + 4 and math.abs(dy) <= SQ / 2 + 4 then
				mode = "sv"
			else
				mode = nil
			end
			if mode then update(input.Position) end
		end
	end)
	lib:connect(UserInputService.InputChanged, function(input)
		if mode and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position)
		end
	end)
	lib:connect(UserInputService.InputEnded, function(input)
		if mode and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			mode = nil
			fire(true)
		end
	end)

	hexBox.FocusLost:Connect(function()
		local txt = hexBox.Text:gsub("[#%s]", "")
		if #txt == 3 then
			txt = txt:sub(1, 1):rep(2) .. txt:sub(2, 2):rep(2) .. txt:sub(3, 3):rep(2)
		end
		if #txt == 6 and txt:match("^%x+$") then
			local parsed = Color3.fromRGB(tonumber(txt:sub(1, 2), 16), tonumber(txt:sub(3, 4), 16), tonumber(txt:sub(5, 6), 16))
			h, s, v = Color3.toHSV(parsed)
			render(parsed)
			fire(true)
		else
			hexBox.Text = hexOf(color)
		end
	end)

	arrow.MouseButton1Click:Connect(function()
		open = not open
		tween(holder, {Size = UDim2.new(1, 0, 0, open and (40 + PANEL_H) or 36)}, 0.22)
		tween(arrow, {Rotation = open and 270 or 90}, 0.22)
	end)

	render(color)
	local api = {Instance = holder}
	function api:Set(c, silent)
		h, s, v = Color3.toHSV(c)
		render(c)
		if not silent then fire(true) end
	end
	return api
end