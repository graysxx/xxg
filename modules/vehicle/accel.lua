return {order = 20, build = function(ctx, tab)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local mult, enabled = 0, false
	local section = tab:addSection("Acceleration")
	local toggle = section:addToggle("Enabled", false, function(v) enabled = v end)
	local slider = section:addSlider("Multiplier (Thousandths)", 0, 0, 50, function(v) mult = v / 1000 end)
	local function reset() slider:Set(0) end
	section:addButton("Reset Acceleration", function()
		reset()
		UI:notify("Acceleration reset", "success")
	end)
	ctx.vehicle.resetters.accel = reset

	local conn = RunService.Stepped:Connect(function()
		if not enabled or UserInputService:GetFocusedTextBox() or not UserInputService:IsKeyDown(Enum.KeyCode.W) then return end
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		local SeatPart = Humanoid and Humanoid.SeatPart
		if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
			SeatPart.AssemblyLinearVelocity *= Vector3.new(1 + mult, 1, 1 + mult)
		end
	end)

	ctx.modules["vehicle.accel"] = {
		collect = function() return {accel = math.floor(mult * 1000 + 0.5), accelEnabled = enabled} end,
		apply = function(d)
			slider:Set(type(d.accel) == "number" and d.accel or 0)
			if type(d.accelEnabled) == "boolean" then toggle:Set(d.accelEnabled) end
		end,
		prepareClose = function() enabled = false end,
		shutdown = function() conn:Disconnect() end,
	}
end}