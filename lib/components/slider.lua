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

	function section:addSlider(title, default, min, max, callback, suffix)
		suffix = suffix or ""
		local value = math.clamp(default or min, min, max)
		local row = newRow(self, 60, "Frame", {Name = "Slider"})
		newLabel({Text = title, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 18),
			TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})

		local track = create("Frame", {
			Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 24),
			BackgroundColor3 = Theme.Panel, BorderSizePixel = 0, Parent = row,
		}, {corner(9), stroke(Theme.AccentLine)})

		local pct0 = (value - min) / (max - min)
		local grad = create("UIGradient", {Color = accentGradient()})
		local fillStroke = create("UIStroke", {
			Color = accentOutline(), Thickness = 1, Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		})
		local fill = create("Frame", {
			Name = "Fill", Size = UDim2.new(pct0, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0, Visible = pct0 > 0, Parent = track,
		}, {corner(9), grad, fillStroke})
		table.insert(themeHooks, function()
			grad.Color = accentGradient()
			fillStroke.Color = accentOutline()
		end)
		fill:SetAttribute("NoTheme", true)

		local box = create("TextBox", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Theme.Text, TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 0.65,
			ClearTextOnFocus = false, TextEditable = false, Text = tostring(value) .. suffix, ZIndex = 3, Parent = track,
		})
		local hit = create("TextButton", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
			ZIndex = 4, Parent = track,
		})

		local function setValue(v)
			v = math.clamp(v, min, max)
			box.Text = tostring(v) .. suffix
			local pct = (v - min) / (max - min)
			fill.Visible = pct > 0
			tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.05)
			if v ~= value then
				value = v
				if callback then task.spawn(callback, value) end
			end
		end

		local function fromX(x)
			local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			setValue(math.floor(min + (max - min) * pct))
		end

		local dragging, lastClick = false, 0
		hit.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local now = os.clock()
				if now - lastClick < 0.35 then 
					lastClick = 0
					dragging = false
					hit.Visible = false
					box.TextEditable = true
					box.Text = tostring(value)
					task.defer(function() box:CaptureFocus() end)
					return
				end
				lastClick = now
				dragging = true
				fromX(input.Position.X)
			end
		end)
		self.library:connect(UserInputService.InputChanged, function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				fromX(input.Position.X)
			end
		end)
		self.library:connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		box.FocusLost:Connect(function()
			box.TextEditable = false
			hit.Visible = true
			local n = tonumber(string.match(box.Text, "-?%d+%.?%d*"))
			if n then
				setValue(math.floor(n))
			else
				box.Text = tostring(value) .. suffix
			end
		end)

		local api = {Instance = row}
		function api:Set(v) setValue(v) end
		return api
	end
end