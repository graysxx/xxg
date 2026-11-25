return {order = 40, build = function(ctx, tab)
	local UI, P = ctx.UI, ctx.player
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local enabled, speed = false, 50
	local bv, bg

	local function stopFly()
		if bv then bv:Destroy(); bv = nil end
		if bg then bg:Destroy(); bg = nil end
		local h = P.humanoid()
		if h then h.PlatformStand = false end
	end

	local section = tab:addSection("Fly")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then stopFly() end
	end)
	local slider = section:addSlider("Speed", 50, 10, 300, function(v) speed = v end)
	section:addButton("Reset Fly", function()
		slider:Set(50)
		UI:notify("Fly reset", "success")
	end)
	section:addLabel("Controls: W/A/S/D to move, Space to go up, Left Shift to go down. Not active while seated in a vehicle.")

	local conn = RunService.Stepped:Connect(function()
		if not enabled then return end
		local h = P.humanoid()
		local root = h and h.RootPart
		if not root or h.SeatPart then
			if bv then stopFly() end
			return
		end
		if not bv or bv.Parent ~= root then
			if bv then bv:Destroy() end
			if bg then bg:Destroy() end
			bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			bv.Velocity = Vector3.zero
			bv.Parent = root
			bg = Instance.new("BodyGyro")
			bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			bg.P = 9e4
			bg.Parent = root
		end
		h.PlatformStand = true
		local cf = workspace.CurrentCamera.CFrame
		local dir = Vector3.zero
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
		end
		bv.Velocity = dir.Magnitude > 0 and dir.Unit * speed or Vector3.zero
		bg.CFrame = cf
	end)

	ctx.modules["player.fly"] = {
		collect = function() return {flySpeed = speed} end,
		apply = function(d) slider:Set(type(d.flySpeed) == "number" and d.flySpeed or 50) end,
		shutdown = function()
			enabled = false
			stopFly()
			conn:Disconnect()
		end,
	}
end}