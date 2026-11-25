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

	function section:addButton(title, callback)
		local btn = newRow(self, 34, "TextButton", {
			Name = "Button", Text = title, AutoButtonColor = false,
			Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = Theme.Text,
		})
		btn.MouseEnter:Connect(function() tween(btn, {BackgroundColor3 = Theme.AccentSoft}) end)
		btn.MouseLeave:Connect(function() tween(btn, {BackgroundColor3 = Theme.Card}) end)
		btn.MouseButton1Click:Connect(function()
			if callback then
				task.spawn(callback, function(newTitle) btn.Text = newTitle end)
			end
		end)
		return btn
	end
end