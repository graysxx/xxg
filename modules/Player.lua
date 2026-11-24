return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer
	local miscPage = ctx.pages.Misc or UI:addPage("Misc")

	local playerOrig = setmetatable({}, {__mode = "k"}) -- [Humanoid] = real value
	local walkEnabled, walkValue = false, 16
	local jumpEnabled, jumpValue = false, 50
	local gravEnabled, gravValue, origGravity = false, 196, workspace.Gravity
	local flyEnabled, flySpeed = false, 50
	local flyBV, flyBG

	local function getHumanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	local function remember(h)
		if not playerOrig[h] then
			playerOrig[h] = {WalkSpeed = h.WalkSpeed, JumpPower = h.JumpPower, UseJumpPower = h.UseJumpPower}
		end
	end
	local function restoreWalk()
		local h = getHumanoid()
		local o = h and playerOrig[h]
		if o then h.WalkSpeed = o.WalkSpeed end
	end
	local function restoreJump()
		local h = getHumanoid()
		local o = h and playerOrig[h]
		if o then h.UseJumpPower = o.UseJumpPower; h.JumpPower = o.JumpPower end
	end
	local function stopFly()
		if flyBV then flyBV:Destroy(); flyBV = nil end
		if flyBG then flyBG:Destroy(); flyBG = nil end
		local h = getHumanoid()
		if h then h.PlatformStand = false end
	end

	-- Walk Speed
	local walkSection = miscPage:addSection("Walk Speed")
	walkSection:addToggle("Enabled", false, function(v)
		walkEnabled = v
		if not v then restoreWalk() end
	end)
	local walkSlider = walkSection:addSlider("Speed", 16, 0, 300, function(v) walkValue = v end)
	walkSection:addButton("Reset Walk Speed", function()
		walkSlider:Set(16)
		UI:notify("Walk Speed reset", "success")
	end)

	-- Jump Power
	local jumpSection = miscPage:addSection("Jump Power")
	jumpSection:addToggle("Enabled", false, function(v)
		jumpEnabled = v
		if not v then restoreJump() end
	end)
	local jumpSlider = jumpSection:addSlider("Power", 50, 0, 300, function(v) jumpValue = v end)
	jumpSection:addButton("Reset Jump Power", function()
		jumpSlider:Set(50)
		UI:notify("Jump Power reset", "success")
	end)

	-- Gravity
	local gravSection = miscPage:addSection("Gravity")
	gravSection:addToggle("Enabled", false, function(v)
		if v and not gravEnabled then origGravity = workspace.Gravity end
		gravEnabled = v
		if not v then workspace.Gravity = origGravity end
	end)
	local gravSlider = gravSection:addSlider("Gravity Value", 196, 0, 400, function(v) gravValue = v end)
	gravSection:addButton("Reset Gravity", function()
		gravSlider:Set(196)
		UI:notify("Gravity reset", "success")
	end)

	-- Fly 
	local flySection = miscPage:addSection("Fly")
	flySection:addToggle("Enabled", false, function(v)
		flyEnabled = v
		if not v then stopFly() end
	end)
	local flySlider = flySection:addSlider("Speed", 50, 10, 300, function(v) flySpeed = v end)
	flySection:addButton("Reset Fly", function()
		flySlider:Set(50)
		UI:notify("Fly reset", "success")
	end)
	flySection:addLabel("Controls: W/A/S/D to move, Space to go up, Left Shift to go down. Not active while seated in a vehicle.")

	-- loop: walk speed, jump, gravity
	local statConn = RunService.Stepped:Connect(function()
		local h = getHumanoid()
		if h and (walkEnabled or jumpEnabled) then
			remember(h)
			if walkEnabled and h.WalkSpeed ~= walkValue then h.WalkSpeed = walkValue end
			if jumpEnabled then
				if not h.UseJumpPower then h.UseJumpPower = true end
				if h.JumpPower ~= jumpValue then h.JumpPower = jumpValue end
			end
		end
		if gravEnabled and workspace.Gravity ~= gravValue then workspace.Gravity = gravValue end
	end)

	-- loop: fly
	local flyConn = RunService.Stepped:Connect(function()
		if not flyEnabled then return end
		local h = getHumanoid()
		local root = h and h.RootPart
		if not root or h.SeatPart then
			if flyBV then stopFly() end
			return
		end
		if not flyBV or flyBV.Parent ~= root then
			if flyBV then flyBV:Destroy() end
			if flyBG then flyBG:Destroy() end
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			flyBV.Velocity = Vector3.zero
			flyBV.Parent = root
			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			flyBG.P = 9e4
			flyBG.Parent = root
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
		flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
		flyBG.CFrame = cf
	end)

	ctx.modules.player = {
		collect = function()
			return {walkSpeed = walkValue, jumpPower = jumpValue, gravity = gravValue, flySpeed = flySpeed}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			walkSlider:Set(num(d.walkSpeed, 16)); jumpSlider:Set(num(d.jumpPower, 50))
			gravSlider:Set(num(d.gravity, 196)); flySlider:Set(num(d.flySpeed, 50))
		end,
		shutdown = function()
			local wasGrav = gravEnabled
			walkEnabled, jumpEnabled, gravEnabled, flyEnabled = false, false, false, false
			stopFly(); restoreWalk(); restoreJump()
			if wasGrav then workspace.Gravity = origGravity end
			statConn:Disconnect(); flyConn:Disconnect()
		end,
	}
end