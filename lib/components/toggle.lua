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

	function section:addToggle(title, default, callback)
		local active = default and true or false
		local row = newRow(self, 36, "TextButton", {Name = "Toggle", Text = "", AutoButtonColor = false})
		newLabel({Text = title, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -64, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = row})
		local track = create("Frame", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 36, 0, 20),
			BackgroundColor3 = Theme.TrackOff, BorderSizePixel = 0, Parent = row,
		}, {corner(10)})
		local knob = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = track,
		}, {corner(7)})

		local function knobColor()
			local a = Theme.Accent
			local light = 0.299 * a.R + 0.587 * a.G + 0.114 * a.B > 0.75
			return (active and light) and Theme.Background or Theme.Text
		end
		local function render(animate)
			apply(track, {BackgroundColor3 = active and Theme.Accent or Theme.TrackOff}, animate)
			apply(knob, {
				Position = active and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				BackgroundColor3 = knobColor(),
			}, animate)
		end
		render(false)
		table.insert(themeHooks, function() render(false) end)

		local api = {Instance = row}
		function api:Set(v)
			active = v and true or false
			render(true)
			if callback then task.spawn(callback, active) end
		end
		function api:Get() return active end

		row.MouseButton1Click:Connect(function() api:Set(not active) end)
		return api
	end
end