return function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local TweenService = game:GetService("TweenService")
	local guiName = "XXGLoader"
	pcall(function() local o = game:GetService("CoreGui"):FindFirstChild(guiName); if o then o:Destroy() end end)
	pcall(function() local o = Players.LocalPlayer.PlayerGui:FindFirstChild(guiName); if o then o:Destroy() end end)

	local function new(class, props, children)
		local o = Instance.new(class)
		local parent
		for k, v in pairs(props or {}) do
			if k == "Parent" then parent = v else o[k] = v end
		end
		for _, c in ipairs(children or {}) do c.Parent = o end
		if parent then o.Parent = parent end
		return o
	end

	local gui = new("ScreenGui", {
		Name = guiName, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	if not pcall(function() gui.Parent = game:GetService("CoreGui") end) then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	local WHITE, MUTED, RED = Color3.fromRGB(245, 245, 247), Color3.fromRGB(139, 141, 152), Color3.fromRGB(239, 68, 68)

	local scale = new("UIScale", {Scale = 0.9})
	local card = new("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(300, 112),
		BackgroundColor3 = Color3.fromRGB(23, 24, 28), BorderSizePixel = 0, GroupTransparency = 1, Parent = gui,
	}, {
		new("UICorner", {CornerRadius = UDim.new(0, 14)}),
		new("UIStroke", {Color = Color3.fromRGB(44, 45, 52), Thickness = 1}),
		scale,
	})

	new("Frame", {
		Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1, Parent = card,
	}, {
		new("UICorner", {CornerRadius = UDim.new(1, 0)}),
		new("UIStroke", {Color = WHITE, Thickness = 3, Transparency = 0.85}),
	})
	local ring = new("Frame", {
		Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1, Parent = card,
	}, {new("UICorner", {CornerRadius = UDim.new(1, 0)})})
	local ringStroke = new("UIStroke", {Color = WHITE, Thickness = 3, Parent = ring})
	local arc = new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15),
			NumberSequenceKeypoint.new(0.75, 0), NumberSequenceKeypoint.new(0.751, 1), NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = ringStroke,
	})

	local title = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(66, 17), Size = UDim2.new(1, -150, 0, 18),
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "XXG", Parent = card,
	})
	local status = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(66, 36), Size = UDim2.new(1, -84, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "Starting...", Parent = card,
	})
	local percent = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 16), Size = UDim2.fromOffset(70, 22),
		BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Right, Text = "0%", Parent = card,
	})
	local fill = new("Frame", {
		Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, {new("UICorner", {CornerRadius = UDim.new(1, 0)})})
	new("Frame", {
		Position = UDim2.new(0, 18, 0, 82), Size = UDim2.new(1, -36, 0, 6), BackgroundColor3 = Color3.fromRGB(44, 45, 52),
		BorderSizePixel = 0, Parent = card,
	}, {new("UICorner", {CornerRadius = UDim.new(1, 0)}), fill})

	TweenService:Create(card, TweenInfo.new(0.25), {GroupTransparency = 0}):Play()
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	local L = {target = 0, shown = 0, failed = false, closed = false}
	local conn = RunService.Heartbeat:Connect(function(dt)
		arc.Rotation = (os.clock() * 320) % 360
		L.shown = L.shown + (L.target - L.shown) * math.min(1, dt * 5)
		if L.target - L.shown < 0.05 then L.shown = L.target end
		percent.Text = math.floor(L.shown + 0.5) .. "%"
		fill.Size = UDim2.new(math.clamp(L.shown / 100, 0, 1), 0, 1, 0)
	end)

	function L.setTitle(t) title.Text = t end
	function L.set(pct, text)
		if L.failed then return end
		L.target = math.max(L.target, math.min(pct, 100))
		if text then status.Text = text end
	end
	function L.close()
		if L.closed then return end
		L.closed = true
		conn:Disconnect()
		TweenService:Create(card, TweenInfo.new(0.3), {GroupTransparency = 1}):Play()
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.9}):Play()
		task.delay(0.4, function() gui:Destroy() end)
	end
	function L.fail(msg)
		L.failed = true
		status.Text = "Failed: " .. tostring(msg):sub(1, 70)
		status.TextColor3 = RED
		fill.BackgroundColor3 = RED
		task.delay(4, L.close)
	end
	function L.finish()
		L.set(100, "Done")
		local t0 = os.clock()
		while L.shown < 99.5 and os.clock() - t0 < 1.5 do task.wait() end
		task.wait(0.2)
		L.close()
	end
	return L
end