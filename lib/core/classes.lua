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

	return function(L)
		local UserInputService = L.UserInputService
		local create, corner, tween = L.create, L.corner, L.tween

		local library, page, section = {}, {}, {}
		library.__index, page.__index, section.__index = library, page, section
		L.library, L.page, L.section = library, page, section
		library.Theme, library.ThemePresets, library.ThemeOrder = L.Theme, L.ThemePresets, L.ThemeOrder

		function library:connect(signal, fn)
			local c = signal:Connect(fn)
			table.insert(self._conns, c)
			return c
		end

		function L.makeDraggable(lib, handle, target)
			local dragging, dragStart, startPos
			lib:connect(handle.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = target.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then dragging = false end
					end)
				end
			end)
			lib:connect(UserInputService.InputChanged, function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local d = input.Position - dragStart
					target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
					if lib.state == "minimized" then lib.normalPos = target.Position end
				end
			end)
		end

		function L.windowButton(parent, x, hoverColor)
			local b = create("TextButton", {
				Position = UDim2.new(0, x, 0, 0), Size = UDim2.new(0, 24, 0, 24),
				BackgroundColor3 = hoverColor, BackgroundTransparency = 1, BorderSizePixel = 0,
				Text = "", AutoButtonColor = false, Parent = parent,
			}, {corner(7)})
			b.MouseEnter:Connect(function() tween(b, {BackgroundTransparency = 0}, 0.12) end)
			b.MouseLeave:Connect(function() tween(b, {BackgroundTransparency = 1}, 0.12) end)
			return b
		end
	end
end