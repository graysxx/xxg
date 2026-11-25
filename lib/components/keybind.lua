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

	function section:addKeybind(title, default, callback, changedCallback, respectProcessed)
		local lib = self.library
		local key = default
		local row = newRow(self, 36, "Frame", {Name = "Keybind"})
		newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
		local btn = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 76, 0, 22),
			BackgroundColor3 = Theme.AccentSoft, BorderSizePixel = 0, AutoButtonColor = false,
			Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = Theme.Accent,
			Text = key and key.Name or "None", Parent = row,
		}, {corner(6), stroke(Theme.AccentLine)})

		-- callback
		lib:connect(UserInputService.InputBegan, function(input, processed)
			if lib.listening then return end
			if respectProcessed and processed then return end
			if key and input.KeyCode == key and callback then
				task.spawn(callback)
			end
		end)

		btn.MouseButton1Click:Connect(function()
			if lib.listening then return end
			lib.listening = true
			btn.Text = "..."
			local conn
			conn = UserInputService.InputBegan:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				conn:Disconnect()
				if input.KeyCode == Enum.KeyCode.Escape then
					btn.Text = key and key.Name or "None"
				else
					key = input.KeyCode
					btn.Text = key.Name
					if changedCallback then task.spawn(changedCallback, input) end
				end
				task.defer(function() lib.listening = false end)
			end)
		end)

		local api = {Instance = row}
		function api:Set(newKey, silent)
			key = newKey
			btn.Text = key and key.Name or "None"
			if not silent and changedCallback then task.spawn(changedCallback, {KeyCode = key}) end
		end
		return api
	end
end