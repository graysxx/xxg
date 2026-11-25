return function(L)
	local UserInputService = L.UserInputService
	local create, corner, tween = L.create, L.corner, L.tween

	local library, page, section = L.library, L.page, L.section
	library.__index, page.__index, section.__index = library, page, section
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