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
end