return function(ctx)
	local UI = ctx.UI
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local page = ctx.pages.Vehicle or UI:addPage("Vehicle")

	local enabled, forceMode = false, false
	local throttlePct, maxSpeed, changeEvery, maxSteerPct = 60, 60, 3, 70
	local steer, steerTarget, nextChange, reverseUntil, lastSeat = 0, 0, 0, 0, nil

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function setInputs(seat, throttle, st)
		pcall(function() seat.ThrottleFloat = throttle end)
		pcall(function() seat.SteerFloat = st end)
		pcall(function() seat.Throttle = (throttle > 0.1 and 1) or (throttle < -0.1 and -1) or 0 end)
		pcall(function() seat.Steer = (st > 0.2 and 1) or (st < -0.2 and -1) or 0 end)
	end

	local function release()
		if lastSeat and lastSeat.Parent then setInputs(lastSeat, 0, 0) end
		steer, steerTarget = 0, 0
	end

	local section = page:addSection("Auto Drive")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then release() end
	end)
	section:addToggle("Force Mode", false, function(v) forceMode = v end)
	local throttleSlider = section:addSlider("Throttle (%)", 60, 10, 100, function(v) throttlePct = v end, "%")
	local speedSlider = section:addSlider("Max Speed (studs/s)", 60, 20, 200, function(v) maxSpeed = v end)
	local steerSlider = section:addSlider("Max Steer (%)", 70, 10, 100, function(v) maxSteerPct = v end, "%")
	local intervalSlider = section:addSlider("Steer Change Interval (s)", 3, 1, 10, function(v) changeEvery = v end)
	section:addButton("Reset Auto Drive", function()
		throttleSlider:Set(60); speedSlider:Set(60); steerSlider:Set(70); intervalSlider:Set(3)
		UI:notify("Auto Drive reset", "success")
	end)
	section:addLabel("Drives the vehicle you are in by itself: random turns, avoids obstacles, reverses when stuck. Holding W/A/S/D pauses it. Force Mode pushes the car directly if the game ignores seat input.")

	-- 
	local function clearance(seat, dir, range)
		local origin = seat.Position + Vector3.new(0, 1, 0)
		local result = workspace:Raycast(origin, dir * range, rayParams)
		if not result or result.Normal.Y > 0.7 then return range end
		return (result.Position - origin).Magnitude
	end

	local function manualInput()
		for _, k in ipairs({Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
			Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right}) do
			if UserInputService:IsKeyDown(k) then return true end
		end
		return false
	end

	local conn = RunService.Stepped:Connect(function(_, dt)
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildWhichIsA("Humanoid")
		local seat = h and h.SeatPart
		if not (seat and seat:IsA("VehicleSeat")) then
			lastSeat = nil
			steer, steerTarget = 0, 0
			return
		end
		lastSeat = seat
		if not enabled then return end
		if not UserInputService:GetFocusedTextBox() and manualInput() then return end

		pcall(function()
			rayParams.FilterDescendantsInstances = {seat:FindFirstAncestorWhichIsA("Model") or seat, c}
			local now = os.clock()
			local fwd, right = seat.CFrame.LookVector, seat.CFrame.RightVector
			local speed = seat.AssemblyLinearVelocity.Magnitude
			local look = 12 + speed * 0.5
			local steerMax = maxSteerPct / 100
			local throttle = throttlePct / 100

			if now < reverseUntil then
				throttle = -0.6 -- reverse
			elseif clearance(seat, fwd, look) < look * 0.7 then
				-- Obstacle detect
				local leftC = clearance(seat, (fwd - right * 0.7).Unit, look)
				local rightC = clearance(seat, (fwd + right * 0.7).Unit, look)
				if math.max(leftC, rightC) < look * 0.5 then
					reverseUntil = now + 1.4
					steerTarget = (math.random() < 0.5 and -1 or 1) * steerMax
					throttle = -0.6
				else
					steerTarget = (rightC > leftC) and steerMax or -steerMax
					throttle = throttle * 0.5
					nextChange = now + 1
				end
			elseif now > nextChange then
				nextChange = now + changeEvery * (0.6 + math.random() * 0.8)
				steerTarget = (math.random() * 2 - 1) * steerMax
			end

			steer = steer + math.clamp(steerTarget - steer, -dt * 1.5, dt * 1.5)
			if throttle > 0 and speed > maxSpeed then throttle = 0 end
			setInputs(seat, throttle, steer)

			if forceMode then
				local vel = seat.AssemblyLinearVelocity
				local want = fwd * (throttle * maxSpeed)
				seat.AssemblyLinearVelocity = vel:Lerp(Vector3.new(want.X, vel.Y, want.Z), math.clamp(dt * 3, 0, 1))
				local up = seat.CFrame.UpVector
				local av = seat.AssemblyAngularVelocity
				local yaw = -steer * 1.6 * math.clamp(speed / 20, 0, 1) -- Ripples: 1.6 rad/s = 91.6 deg/s
				seat.AssemblyAngularVelocity = av - up * av:Dot(up) + up * yaw
			end
		end)
	end)

	ctx.modules.autodrive = {
		collect = function()
			return {throttle = throttlePct, maxSpeed = maxSpeed, maxSteer = maxSteerPct, interval = changeEvery}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			throttleSlider:Set(num(d.throttle, 60)); speedSlider:Set(num(d.maxSpeed, 60))
			steerSlider:Set(num(d.maxSteer, 70)); intervalSlider:Set(num(d.interval, 3))
		end,
		prepareClose = function() enabled = false end,
		shutdown = function()
			enabled = false
			release()
			conn:Disconnect()
		end,
	}
end