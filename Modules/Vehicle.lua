return function(ctx)
	local UI, Theme = ctx.UI, ctx.Theme
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer

	-- ====================================================================
	-- LOGIKA ASLI
	-- ====================================================================
	local function GetVehicleFromDescendant(Descendant)
		return
			Descendant:FindFirstAncestor(LocalPlayer.Name .. "\'s Car") or
			(Descendant:FindFirstAncestor("Body") and Descendant:FindFirstAncestor("Body").Parent) or
			(Descendant:FindFirstAncestor("Misc") and Descendant:FindFirstAncestor("Misc").Parent) or
			Descendant:FindFirstAncestorWhichIsA("Model")
	end

	local function TeleportVehicle(CoordinateFrame: CFrame)
		local Parent = LocalPlayer.Character.Parent
		local Vehicle = GetVehicleFromDescendant(LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").SeatPart)
		LocalPlayer.Character.Parent = Vehicle
		local success, response = pcall(function()
			return Vehicle:SetPrimaryPartCFrame(CoordinateFrame)
		end)
		if not success then
			return Vehicle:MoveTo(CoordinateFrame.Position)
		end
	end

	-- ====================================================================
	-- PAGE: VEHICLE
	-- ====================================================================
	local vehiclePage = UI:addPage("Vehicle")
	ctx.pages.Vehicle = vehiclePage

	-- ----- Flight -----
	local flightSection = vehiclePage:addSection("Flight")
	local flightEnabled = false
	local flightSpeed = 1
	local flightToggle = flightSection:addToggle("Enabled", false, function(v) flightEnabled = v end)
	local flightSlider = flightSection:addSlider("Speed", 100, 0, 800, function(v) flightSpeed = v / 100 end)
	flightSection:addButton("Reset Flight", function()
		flightSlider:Set(100)
		UI:notify("Flight reset", "success")
	end)
	local defaultCharacterParent
	local flightConnection = RunService.Stepped:Connect(function()
		local Character = LocalPlayer.Character
		if flightEnabled == true then
			if Character and typeof(Character) == "Instance" then
				local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
				if Humanoid and typeof(Humanoid) == "Instance" then
					local SeatPart = Humanoid.SeatPart
					if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
						local Vehicle = GetVehicleFromDescendant(SeatPart)
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

	-- ----- Acceleration -----
	local speedSection = vehiclePage:addSection("Acceleration")
	local velocityMult = 0
	local accelEnabled = false
	local accelToggle = speedSection:addToggle("Enabled", false, function(v) accelEnabled = v end)
	local accelSlider = speedSection:addSlider("Multiplier (Thousandths)", 0, 0, 50, function(v) velocityMult = v / 1000 end)
	speedSection:addButton("Reset Acceleration", function()
		accelSlider:Set(0)
		UI:notify("Acceleration reset", "success")
	end)

	-- ----- Deceleration -----
	local decelerateSelection = vehiclePage:addSection("Deceleration")
	local velocityMult2 = 0
	local brakeEnabled = false
	local brakeToggle = decelerateSelection:addToggle("Enabled", false, function(v) brakeEnabled = v end)
	local brakeSlider = decelerateSelection:addSlider("Brake Force (Thousandths)", 0, 0, 300, function(v) velocityMult2 = v / 1000 end)
	local driveConnection = RunService.Stepped:Connect(function()
		if not (accelEnabled or brakeEnabled) then return end
		if UserInputService:GetFocusedTextBox() then return end -- tidak aktif saat mengetik
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		local SeatPart = Humanoid and Humanoid.SeatPart
		if SeatPart and typeof(SeatPart) == "Instance" and SeatPart:IsA("VehicleSeat") then
			if accelEnabled and UserInputService:IsKeyDown(Enum.KeyCode.W) then
				SeatPart.AssemblyLinearVelocity *= Vector3.new(1 + velocityMult, 1, 1 + velocityMult)
			end
			if brakeEnabled and UserInputService:IsKeyDown(Enum.KeyCode.S) then
				SeatPart.AssemblyLinearVelocity *= Vector3.new(1 - velocityMult2, 1, 1 - velocityMult2)
			end
		end
	end)
	decelerateSelection:addButton("Reset Deceleration", function()
		brakeSlider:Set(0)
		UI:notify("Deceleration reset", "success")
	end)

	-- ====================================================================
	-- HANDLING EDITOR (suspensi & setir) + GROUND SNAPPING
	-- ====================================================================
	local handlingEnabled = false
	local suspStiffF, suspStiffR = 100, 100
	local suspDampF, suspDampR = 100, 100
	local swapAxles = false
	local steerResponse, steerAssist = 100, 0
	local snapEnabled, snapStrength, snapRange, snapAlign = false, 50, 12, true

	local handlingVehicle
	local originals = {}
	local axleOf = {}
	local snapLowest = math.huge
	local lastScan, scanCount = 0, 0
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function restoreHandling()
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

		-- depan / belakang: posisi tiap pegas terhadap arah hadap kursi (depan = -Z), dibagi di titik tengah
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
			if swapAxles then front = not front end
			axleOf[sp] = front and "front" or "rear"
		end

		-- servo yang bernama "steer" dipakai kalau ada; kalau tidak, semua servo dianggap setir
		for _, hinge in ipairs(#steering > 0 and steering or servos) do
			originals[hinge] = {AngularSpeed = hinge.AngularSpeed, ServoMaxTorque = hinge.ServoMaxTorque}
		end
		if seat:IsA("VehicleSeat") then
			originals[seat] = {TurnSpeed = seat.TurnSpeed}
		end
		handlingVehicle = vehicle
	end

	local handlingConnection = RunService.Stepped:Connect(function(_, dt)
		local Character = LocalPlayer.Character
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		local seat = Humanoid and Humanoid.SeatPart
		if not (seat and typeof(seat) == "Instance" and seat:IsA("VehicleSeat")) then seat = nil end
		local vehicle = seat and GetVehicleFromDescendant(seat)

		-- turun / ganti kendaraan: kembalikan nilai asli kendaraan sebelumnya
		if handlingVehicle and vehicle ~= handlingVehicle then
			restoreHandling()
		end
		if not seat or not vehicle or not vehicle:IsA("Model") or flightEnabled then
			snapLowest = math.huge
			return
		end

		pcall(function()
			-- ----- Handling editor -----
			if handlingEnabled then
				if handlingVehicle == vehicle and os.clock() - lastScan > 2 then
					lastScan = os.clock()
					if #vehicle:GetDescendants() ~= scanCount then restoreHandling() end
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
							local k = orig.Stiffness * (front and suspStiffF or suspStiffR) / 100
							local c = orig.Damping * (front and suspDampF or suspDampR) / 100
							if inst.Stiffness ~= k then inst.Stiffness = k end
							if inst.Damping ~= c then inst.Damping = c end
						elseif inst:IsA("HingeConstraint") then
							local sp, tq = orig.AngularSpeed * steerResponse / 100, orig.ServoMaxTorque * steerResponse / 100
							if inst.AngularSpeed ~= sp then inst.AngularSpeed = sp end
							if inst.ServoMaxTorque ~= tq then inst.ServoMaxTorque = tq end
						elseif inst:IsA("VehicleSeat") then
							local ts = orig.TurnSpeed * steerResponse / 100
							if inst.TurnSpeed ~= ts then inst.TurnSpeed = ts end
						end
					end
				end

				-- bantuan belok
				if steerAssist > 0 and not UserInputService:GetFocusedTextBox() then
					local steer = seat.SteerFloat
					if steer == 0 then
						steer = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1) or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1) or 0
					end
					if steer ~= 0 then
						local speedFactor = math.clamp(seat.AssemblyLinearVelocity.Magnitude / 25, 0, 1)
						local up = seat.CFrame.UpVector
						local av = seat.AssemblyAngularVelocity
						local yawRate = av:Dot(up)
						local target = -steer * 2.2 * (steerAssist / 100) * speedFactor
						local delta = math.clamp(target - yawRate, -6 * dt, 6 * dt)
						if (target > 0 and delta > 0) or (target < 0 and delta < 0) then
							seat.AssemblyAngularVelocity = av + up * delta
						end
					end
				end
			end

			-- ----- Ground snapping -----
			if snapEnabled then
				rayParams.FilterDescendantsInstances = {vehicle, Character}
				local origin = seat.Position
				local result = workspace:Raycast(origin, Vector3.new(0, -snapRange, 0), rayParams)
				if result then
					local dist = (origin - result.Position).Magnitude
					snapLowest = math.min(dist, snapLowest + dt * 0.1)
					local airborne = dist > snapLowest + 1
					local speed = seat.AssemblyLinearVelocity.Magnitude
					local pull = (snapStrength / 100) * 120 * (0.3 + 0.7 * math.clamp(speed / 30, 0, 1))
					if airborne then pull = pull * 1.5 end
					seat:ApplyImpulse(Vector3.new(0, -seat.AssemblyMass * pull * dt, 0))

					if snapAlign and airborne then
						local up = seat.CFrame.UpVector
						local axis = up:Cross(result.Normal)
						local av = seat.AssemblyAngularVelocity
						local yaw = up * av:Dot(up)
						local gain = math.clamp(dt * 6 * (snapStrength / 100 + 0.2), 0, 1)
						seat.AssemblyAngularVelocity = yaw + (av - yaw):Lerp(axis * 4, gain)
					end
				end
			else
				snapLowest = math.huge
			end
		end)
	end)

	-- ----- Handling Editor (card) -----
	local handlingSection = vehiclePage:addSection("Handling Editor")
	local stiffFSlider, stiffRSlider, dampFSlider, dampRSlider, respSlider, assistSlider, suspPreset, steerPreset
	local applyingPreset = false
	local handlingToggle = handlingSection:addToggle("Enabled", false, function(v)
		handlingEnabled = v
		if not v then restoreHandling() end
	end)
	handlingSection:addButton("Reset Handling", function()
		applyingPreset = true
		stiffFSlider:Set(100); stiffRSlider:Set(100); dampFSlider:Set(100); dampRSlider:Set(100)
		respSlider:Set(100); assistSlider:Set(0)
		applyingPreset = false
		suspPreset:Set("Normal"); steerPreset:Set("Normal")
		UI:notify("Handling reset", "success")
	end)
	handlingSection:addLabel("Adjusts the suspension and steering of the vehicle you are driving. Original values are restored automatically when disabled, when you get out, or when you change vehicles.")

	-- ----- Suspension -----
	local suspSection = vehiclePage:addSection("Suspension")
	-- urutan: {stiffness depan, stiffness belakang, damping depan, damping belakang} (% dari nilai asli)
	local suspPresets = {
		Soft   = {60, 60, 80, 80},
		Normal = {100, 100, 100, 100},
		Sport  = {160, 170, 140, 150},
		Stiff  = {250, 250, 200, 200},
		Drag   = {70, 220, 90, 180},
		Drift  = {140, 80, 120, 90},
	}
	suspPreset = suspSection:addDropdown("Preset", {"Soft", "Normal", "Sport", "Stiff", "Drag", "Drift"}, function(name)
		local p = suspPresets[name]
		if not p then return end
		applyingPreset = true
		stiffFSlider:Set(p[1]); stiffRSlider:Set(p[2]); dampFSlider:Set(p[3]); dampRSlider:Set(p[4])
		applyingPreset = false
	end)
	local function suspCustom()
		if not applyingPreset then suspPreset:Set("Custom") end
	end
	stiffFSlider = suspSection:addSlider("Front Stiffness", 100, 25, 400, function(v) suspStiffF = v; suspCustom() end, "%")
	stiffRSlider = suspSection:addSlider("Rear Stiffness", 100, 25, 400, function(v) suspStiffR = v; suspCustom() end, "%")
	dampFSlider = suspSection:addSlider("Front Damping", 100, 25, 400, function(v) suspDampF = v; suspCustom() end, "%")
	dampRSlider = suspSection:addSlider("Rear Damping", 100, 25, 400, function(v) suspDampR = v; suspCustom() end, "%")
	local swapToggle = suspSection:addToggle("Swap Front / Rear", false, function(v)
		swapAxles = v
		restoreHandling() -- hitung ulang depan / belakang di frame berikutnya
	end)
	suspSection:addButton("Reset Suspension", function()
		applyingPreset = true
		stiffFSlider:Set(100); stiffRSlider:Set(100); dampFSlider:Set(100); dampRSlider:Set(100)
		applyingPreset = false
		suspPreset:Set("Normal")
		UI:notify("Suspension reset", "success")
	end)

	-- ----- Steering -----
	local steerSection = vehiclePage:addSection("Steering")
	local steerPresets = {Heavy = {60, 0}, Normal = {100, 0}, Light = {160, 25}, ["Very Light"] = {220, 50}, Drift = {220, 70}}
	steerPreset = steerSection:addDropdown("Preset", {"Heavy", "Normal", "Light", "Very Light", "Drift"}, function(name)
		local p = steerPresets[name]
		if not p then return end
		applyingPreset = true
		respSlider:Set(p[1]); assistSlider:Set(p[2])
		applyingPreset = false
	end)
	respSlider = steerSection:addSlider("Response", 100, 40, 250, function(v)
		steerResponse = v
		if not applyingPreset then steerPreset:Set("Custom") end
	end, "%")
	assistSlider = steerSection:addSlider("Turn Assist", 0, 0, 100, function(v)
		steerAssist = v
		if not applyingPreset then steerPreset:Set("Custom") end
	end, "%")
	steerSection:addButton("Reset Steering", function()
		applyingPreset = true
		respSlider:Set(100); assistSlider:Set(0)
		applyingPreset = false
		steerPreset:Set("Normal")
		UI:notify("Steering reset", "success")
	end)

	-- ----- Ground Snapping -----
	local snapSection = vehiclePage:addSection("Ground Snapping")
	local snapToggle = snapSection:addToggle("Enabled", false, function(v)
		snapEnabled = v
		snapLowest = math.huge
	end)
	local snapStrengthSlider = snapSection:addSlider("Strength", 50, 0, 100, function(v) snapStrength = v end, "%")
	local snapRangeSlider = snapSection:addSlider("Range (studs)", 12, 4, 40, function(v) snapRange = v end)
	local snapAlignToggle = snapSection:addToggle("Align to Road", true, function(v) snapAlign = v end)
	snapSection:addButton("Reset Ground Snapping", function()
		snapStrengthSlider:Set(50); snapRangeSlider:Set(12)
		UI:notify("Ground Snapping reset", "success")
	end)

	-- ----- Reset All -----
	local resetAllSection = vehiclePage:addSection("Reset All")
	resetAllSection:addButton("Reset All Vehicle Settings", function()
		applyingPreset = true
		flightSlider:Set(100)
		accelSlider:Set(0)
		brakeSlider:Set(0)
		stiffFSlider:Set(100); stiffRSlider:Set(100); dampFSlider:Set(100); dampRSlider:Set(100)
		respSlider:Set(100); assistSlider:Set(0)
		snapStrengthSlider:Set(50); snapRangeSlider:Set(12)
		applyingPreset = false
		suspPreset:Set("Normal"); steerPreset:Set("Normal")
		UI:notify("All vehicle values reset", "success")
	end)
	resetAllSection:addLabel("Resets all values to default. Toggle positions are not changed.")

	-- ====================================================================
	-- daftar ke ConfigManager (save/load) dan Main (close)
	-- ====================================================================
	ctx.modules.vehicle = {
		collect = function()
			return {
				flightSpeed = math.floor(flightSpeed * 100 + 0.5),
				accel = math.floor(velocityMult * 1000 + 0.5),
				brake = math.floor(velocityMult2 * 1000 + 0.5),
				handlingEnabled = handlingEnabled,
				suspStiffF = suspStiffF, suspStiffR = suspStiffR,
				suspDampF = suspDampF, suspDampR = suspDampR,
				swapAxles = swapAxles,
				steerResponse = steerResponse, steerAssist = steerAssist,
				snapEnabled = snapEnabled, snapStrength = snapStrength, snapRange = snapRange, snapAlign = snapAlign,
				accelEnabled = accelEnabled, brakeEnabled = brakeEnabled,
			}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			applyingPreset = true
			flightSlider:Set(num(d.flightSpeed, 100))
			accelSlider:Set(num(d.accel, 0))
			brakeSlider:Set(num(d.brake, 0))
			stiffFSlider:Set(num(d.suspStiffF, 100)); stiffRSlider:Set(num(d.suspStiffR, 100))
			dampFSlider:Set(num(d.suspDampF, 100));   dampRSlider:Set(num(d.suspDampR, 100))
			respSlider:Set(num(d.steerResponse, 100)); assistSlider:Set(num(d.steerAssist, 0))
			snapStrengthSlider:Set(num(d.snapStrength, 50)); snapRangeSlider:Set(num(d.snapRange, 12))
			applyingPreset = false
			suspPreset:Set("Custom"); steerPreset:Set("Custom")

			if type(d.swapAxles) == "boolean" then swapToggle:Set(d.swapAxles) end
			if type(d.snapAlign) == "boolean" then snapAlignToggle:Set(d.snapAlign) end
			if type(d.snapEnabled) == "boolean" then snapToggle:Set(d.snapEnabled) end
			if type(d.handlingEnabled) == "boolean" then handlingToggle:Set(d.handlingEnabled) end
			if type(d.accelEnabled) == "boolean" then accelToggle:Set(d.accelEnabled) end
			if type(d.brakeEnabled) == "boolean" then brakeToggle:Set(d.brakeEnabled) end
		end,
		prepareClose = function()
			flightEnabled = false      -- biar karakter dikembalikan ke parent semula
			accelEnabled = false; brakeEnabled = false
		end,
		shutdown = function()
			handlingEnabled = false
			snapEnabled = false
			restoreHandling()          -- kembalikan suspensi & setir ke nilai asli
			handlingConnection:Disconnect()
			flightConnection:Disconnect()
			driveConnection:Disconnect()
		end,
	}
end