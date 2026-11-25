return {order = 1, page = false, build = function(ctx)
	local V = ctx.vehicle
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local H = {
		enabled = false, stiffF = 100, stiffR = 100, dampF = 100, dampR = 100, swap = false,
		response = 100, assist = 0,
		snapEnabled = false, snapStrength = 50, snapRange = 12, snapAlign = true,
		applying = false, ui = {},
	}
	V.h = H

	local handlingVehicle
	local originals, axleOf = {}, {}
	local snapLowest = math.huge
	local lastScan, scanCount = 0, 0
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	function H.restore()
		for inst, props in pairs(originals) do
			if inst.Parent then
				for name, value in pairs(props) do
					pcall(function() inst[name] = value end)
				end
			end
		end
		originals, axleOf = {}, {}
		handlingVehicle = nil
	end
	function H.resetSnap() snapLowest = math.huge end

	local function looksLikeSteering(hinge)
		local function has(x)
			return x ~= nil and string.find(string.lower(x.Name), "steer") ~= nil
		end
		local a0 = hinge.Attachment0
		return has(hinge) or has(hinge.Parent) or (a0 ~= nil and (has(a0) or has(a0.Parent)))
	end

	local function collectHandling(vehicle, seat)
		originals, axleOf = {}, {}
		local springs, servos, steering = {}, {}, {}
		for _, d in ipairs(vehicle:GetDescendants()) do
			if d:IsA("SpringConstraint") then
				originals[d] = {Stiffness = d.Stiffness, Damping = d.Damping}
				table.insert(springs, d)
			elseif d:IsA("HingeConstraint") and d.ActuatorType == Enum.ActuatorType.Servo then
				table.insert(servos, d)
				if looksLikeSteering(d) then table.insert(steering, d) end
			end
		end

		-- Front / Rear
		local zs, sum = {}, 0
		for i, sp in ipairs(springs) do
			local att = sp.Attachment0 or sp.Attachment1
			local pos = att and att.WorldPosition
			if not pos then
				pos = (sp.Parent and sp.Parent:IsA("BasePart")) and sp.Parent.Position or seat.Position
			end
			zs[i] = seat.CFrame:PointToObjectSpace(pos).Z
			sum = sum + zs[i]
		end
		local mean = #springs > 0 and sum / #springs or 0
		for i, sp in ipairs(springs) do
			local front = zs[i] < mean - 0.01
			if H.swap then front = not front end
			axleOf[sp] = front and "front" or "rear"
		end

		for _, hinge in ipairs(#steering > 0 and steering or servos) do
			originals[hinge] = {AngularSpeed = hinge.AngularSpeed, ServoMaxTorque = hinge.ServoMaxTorque}
		end
		if seat:IsA("VehicleSeat") then
			originals[seat] = {TurnSpeed = seat.TurnSpeed}
		end
		handlingVehicle = vehicle
	end

	local conn = RunService.Stepped:Connect(function(_, dt)
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		local seat = Humanoid and Humanoid.SeatPart
		if not (seat and typeof(seat) == "Instance" and seat:IsA("VehicleSeat")) then seat = nil end
		local vehicle = seat and V.getVehicle(seat)

		if handlingVehicle and vehicle ~= handlingVehicle then H.restore() end
		if not seat or not vehicle or not vehicle:IsA("Model") or V.flightEnabled then
			snapLowest = math.huge
			return
		end

		pcall(function()
			-- ----- Handling editor -----
			if H.enabled then
				if handlingVehicle == vehicle and os.clock() - lastScan > 2 then
					lastScan = os.clock()
					if #vehicle:GetDescendants() ~= scanCount then H.restore() end
				end
				if handlingVehicle ~= vehicle then
					collectHandling(vehicle, seat)
					scanCount = #vehicle:GetDescendants()
					lastScan = os.clock()
				end
				for inst, orig in pairs(originals) do
					if inst.Parent then
						if inst:IsA("SpringConstraint") then
							local front = axleOf[inst] ~= "rear"
							local k = orig.Stiffness * (front and H.stiffF or H.stiffR) / 100
							local c = orig.Damping * (front and H.dampF or H.dampR) / 100
							if inst.Stiffness ~= k then inst.Stiffness = k end
							if inst.Damping ~= c then inst.Damping = c end
						elseif inst:IsA("HingeConstraint") then
							local sp, tq = orig.AngularSpeed * H.response / 100, orig.ServoMaxTorque * H.response / 100
							if inst.AngularSpeed ~= sp then inst.AngularSpeed = sp end
							if inst.ServoMaxTorque ~= tq then inst.ServoMaxTorque = tq end
						elseif inst:IsA("VehicleSeat") then
							local ts = orig.TurnSpeed * H.response / 100
							if inst.TurnSpeed ~= ts then inst.TurnSpeed = ts end
						end
					end
				end

				-- Steering Assist
				if H.assist > 0 and not UserInputService:GetFocusedTextBox() then
					local steer = seat.SteerFloat
					if steer == 0 then
						steer = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1) or 0
					end
					if steer ~= 0 then
						local speedFactor = math.clamp(seat.AssemblyLinearVelocity.Magnitude / 25, 0, 1)
						local up = seat.CFrame.UpVector
						local av = seat.AssemblyAngularVelocity
						local yawRate = av:Dot(up)
						local target = -steer * 2.2 * (H.assist / 100) * speedFactor
						local delta = math.clamp(target - yawRate, -6 * dt, 6 * dt)
						if (target > 0 and delta > 0) or (target < 0 and delta < 0) then
							seat.AssemblyAngularVelocity = av + up * delta
						end
					end
				end
			end

			-- ----- Ground snapping -----
			if H.snapEnabled then
				rayParams.FilterDescendantsInstances = {vehicle, Character}
				local origin = seat.Position
				local result = workspace:Raycast(origin, Vector3.new(0, -H.snapRange, 0), rayParams)
				if result then
					local dist = (origin - result.Position).Magnitude
					snapLowest = math.min(dist, snapLowest + dt * 0.1)
					local airborne = dist > snapLowest + 1
					local speed = seat.AssemblyLinearVelocity.Magnitude
					local pull = (H.snapStrength / 100) * 120 * (0.3 + 0.7 * math.clamp(speed / 30, 0, 1))
					if airborne then pull = pull * 1.5 end
					seat:ApplyImpulse(Vector3.new(0, -seat.AssemblyMass * pull * dt, 0))

					if H.snapAlign and airborne then
						local up = seat.CFrame.UpVector
						local axis = up:Cross(result.Normal)
						local av = seat.AssemblyAngularVelocity
						local yaw = up * av:Dot(up)
						local gain = math.clamp(dt * 6 * (H.snapStrength / 100 + 0.2), 0, 1)
						seat.AssemblyAngularVelocity = yaw + (av - yaw):Lerp(axis * 4, gain)
					end
				end
			else
				snapLowest = math.huge
			end
		end)
	end)

	ctx.modules["vehicle.core"] = {
		shutdown = function()
			H.enabled, H.snapEnabled = false, false
			H.restore()
			conn:Disconnect()
		end,
	}
end}