return {order = 30, build = function(ctx, tab)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local mult, enabled = 0, false
	local section = tab:addSection("Deceleration")
	local toggle = section:addToggle("Enabled", false, function(v) enabled = v end)
	local slider = section:addSlider("Brake Force (Thousandths)", 0, 0, 300, function(v) mult = v / 1000 end)
	local function reset() slider:Set(0) end
	section:addButton("Reset Deceleration", function()
		reset()
		UI:notify("Deceleration reset", "success")
	end)
	ctx.vehicle.resetters.brake = reset

	local conn = RunService.Stepped:Connect(function()
		if not enabled or UserInputService:GetFocusedTextBox() or not UserInputService:IsKeyDown(Enum.KeyCode.S) then return end
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		local SeatPart = Humanoid and Humanoid.SeatPart
		if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
			SeatPart.AssemblyLinearVelocity *= Vector3.new(1 - mult, 1, 1 - mult)
		end
	end)

	ctx.modules["vehicle.brake"] = {
		collect = function() return {brake = math.floor(mult * 1000 + 0.5), brakeEnabled = enabled} end,
		apply = function(d)
			slider:Set(type(d.brake) == "number" and d.brake or 0)
			if type(d.brakeEnabled) == "boolean" then toggle:Set(d.brakeEnabled) end
		end,
		prepareClose = function() enabled = false end,
		shutdown = function() conn:Disconnect() end,
	}
end}