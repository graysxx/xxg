return {order = 10, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local flightSpeed = 1
	local defaultCharacterParent

	local section = tab:addSection("Flight")
	section:addToggle("Enabled", false, function(v) V.flightEnabled = v end)
	local slider = section:addSlider("Speed", 100, 0, 800, function(v) flightSpeed = v / 100 end)
	local function reset() slider:Set(100) end
	section:addButton("Reset Flight", function()
		reset()
		UI:notify("Flight reset", "success")
	end)
	V.resetters.flight = reset

	local conn = RunService.Stepped:Connect(function()
		local Character = LocalPlayer.Character
		if V.flightEnabled == true then
			if Character and typeof(Character) == "Instance" then
				local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
				if Humanoid and typeof(Humanoid) == "Instance" then
					local SeatPart = Humanoid.SeatPart
					if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
						local Vehicle = V.getVehicle(SeatPart)
						if Vehicle and Vehicle:IsA("Model") then
							Character.Parent = Vehicle
							if not Vehicle.PrimaryPart then
								if SeatPart.Parent == Vehicle then
									Vehicle.PrimaryPart = SeatPart
								else
									Vehicle.PrimaryPart = Vehicle:FindFirstChildWhichIsA("BasePart")
								end
							end
							local PrimaryPartCFrame = Vehicle:GetPrimaryPartCFrame()
							Vehicle:SetPrimaryPartCFrame(CFrame.new(PrimaryPartCFrame.Position, PrimaryPartCFrame.Position + workspace.CurrentCamera.CFrame.LookVector) * (UserInputService:GetFocusedTextBox() and CFrame.new(0, 0, 0) or CFrame.new((UserInputService:IsKeyDown(Enum.KeyCode.D) and flightSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -flightSpeed) or 0, (UserInputService:IsKeyDown(Enum.KeyCode.E) and flightSpeed / 2) or (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -flightSpeed / 2) or 0, (UserInputService:IsKeyDown(Enum.KeyCode.S) and flightSpeed) or (UserInputService:IsKeyDown(Enum.KeyCode.W) and -flightSpeed) or 0)))
							SeatPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
							SeatPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
						end
					end
				end
			end
		else
			if Character and typeof(Character) == "Instance" then
				Character.Parent = defaultCharacterParent or Character.Parent
				defaultCharacterParent = Character.Parent
			end
		end
	end)

	ctx.modules["vehicle.flight"] = {
		collect = function() return {flightSpeed = math.floor(flightSpeed * 100 + 0.5)} end,
		apply = function(d) slider:Set(type(d.flightSpeed) == "number" and d.flightSpeed or 100) end,
		prepareClose = function() V.flightEnabled = false end,
		shutdown = function() conn:Disconnect() end,
	}
end}