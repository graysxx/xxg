return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = Players.LocalPlayer
	local page = ctx.pages.Vehicle or UI:addPage("Vehicle")
	local K = Enum.KeyCode

	local VIM
	pcall(function() VIM = game:GetService("VirtualInputManager") end)

	-- ===== settings =====
	local enabled = false
	local inputMode, transMode = "Keyboard", "Automatic"   -- Keyboard | Seat ; Automatic | Semi | Manual
	local throttlePct, maxSpeed, changeEvery, maxSteerPct = 60, 60, 3, 70
	local upRPM, downRPM = 6000, 2500
	local keys = {Handbrake = K.P, ShiftUp = K.E, ShiftDown = K.Q, Clutch = K.LeftShift}

	-- ===== state =====
	local steer, steerTarget, nextChange, reverseUntil, stuckTime = 0, 0, 0, 0, 0
	local phase, refreshTimer, lastShift, internalGear = 0, 0, 0, 1
	local shifting, handChecked = false, false
	local scannedSeat, det = nil, nil
	local infoVehicle, infoHand, infoGear, infoRPM, infoTrans

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- ===== virtual keyboard =====
	local held, ignoreUntil = {}, {}
	local function setKey(key, down)
		if not VIM or (held[key] or false) == down then return end
		held[key] = down or nil
		if not down then ignoreUntil[key] = os.clock() + 0.15 end
		pcall(function() VIM:SendKeyEvent(down, key, false, game) end)
	end
	local function releaseAll()
		if not VIM then return end
		for key in pairs(held) do
			ignoreUntil[key] = os.clock() + 0.15
			pcall(function() VIM:SendKeyEvent(false, key, false, game) end)
		end
		table.clear(held)
	end
	local function tap(key, dur)
		setKey(key, true)
		task.wait(dur or 0.06)
		setKey(key, false)
	end

	local watch = {K.W, K.A, K.S, K.D, K.Up, K.Down, K.Left, K.Right}
	local function manualInput()
		local now = os.clock()
		for _, k in ipairs(watch) do
			if not held[k] and (ignoreUntil[k] or 0) < now and UserInputService:IsKeyDown(k) then return true end
		end
		return false
	end

	-- ===== mode Seat =====
	local currentSeat
	local function setSeatInputs(seat, throttle, st)
		pcall(function() seat.ThrottleFloat = throttle end)
		pcall(function() seat.SteerFloat = st end)
		pcall(function() seat.Throttle = (throttle > 0.1 and 1) or (throttle < -0.1 and -1) or 0 end)
		pcall(function() seat.Steer = (st > 0.2 and 1) or (st < -0.2 and -1) or 0 end)
	end
	local function releaseInputs()
		releaseAll()
		if currentSeat and currentSeat.Parent then setSeatInputs(currentSeat, 0, 0) end
		steer, steerTarget = 0, 0
	end

	-- ===== scan vehicle =====
	local function matches(name, patterns, excludes)
		local n = string.lower(name)
		for _, ex in ipairs(excludes) do if n:find(ex, 1, true) then return false end end
		for _, p in ipairs(patterns) do if n:find(p, 1, true) then return true end end
		return false
	end

	local function consider(r, name, get)
		local ok, v = pcall(get)
		if not ok then return end
		local t = type(v)
		if not r.gear and t == "number" and matches(name, {"gear"}, {"ratio", "final", "max", "count", "shift", "limit"}) then
			r.gear = {name = name, get = get}
		elseif not r.rpm and t == "number" and matches(name, {"rpm"}, {"max", "redline", "idle", "limit"}) then
			r.rpm = {name = name, get = get}
		elseif not r.hand and (t == "boolean" or t == "number") and matches(name,
			{"handbrake", "hand_brake", "hand brake", "ebrake", "e_brake", "pbrake", "p_brake", "parkbrake", "parkingbrake", "hbrake"}, {}) then
			r.hand = {name = name, get = get}
		elseif not r.trans and t == "string" and matches(name, {"transmission", "transmode", "trans_mode", "gearbox"}, {}) then
			r.trans = {name = name, get = get}
		end
	end

	local function scan(seat)
		local model = seat:FindFirstAncestorWhichIsA("Model") or seat.Parent
		local r = {model = model, seat = seat, values = {}, scripts = {}, remotes = {}, attrs = {}}
		local function attrs(inst)
			for k, v in pairs(inst:GetAttributes()) do
				table.insert(r.attrs, inst:GetFullName() .. " @" .. k .. " = " .. tostring(v))
				consider(r, k, function() return inst:GetAttribute(k) end)
			end
		end
		attrs(seat)
		if model then
			attrs(model)
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("ValueBase") then
					local ok, v = pcall(function() return d.Value end)
					if #r.values < 150 then
						table.insert(r.values, d:GetFullName() .. " [" .. d.ClassName .. "] = " .. tostring(ok and v or "?"))
					end
					consider(r, d.Name, function() return d.Value end)
				elseif d:IsA("LuaSourceContainer") then
					if #r.scripts < 40 then table.insert(r.scripts, d:GetFullName() .. " [" .. d.ClassName .. "]") end
				elseif d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
					if #r.remotes < 40 then table.insert(r.remotes, d:GetFullName() .. " [" .. d.ClassName .. "]") end
				end
			end
		end
		return r
	end

	local function dumpScan(r)
		local lines = {}
		local function add(s) table.insert(lines, s) end
		add("Model: " .. (r.model and r.model:GetFullName() or "?"))
		add("Seat: " .. r.seat:GetFullName() .. " [" .. r.seat.ClassName .. "]")
		if r.seat:IsA("VehicleSeat") then
			add(string.format("VehicleSeat MaxSpeed=%s Torque=%s TurnSpeed=%s", r.seat.MaxSpeed, r.seat.Torque, r.seat.TurnSpeed))
		end
		add("Detected gear: " .. (r.gear and r.gear.name or "-") .. " | rpm: " .. (r.rpm and r.rpm.name or "-")
			.. " | handbrake: " .. (r.hand and r.hand.name or "-") .. " | transmission: " .. (r.trans and r.trans.name or "-"))
		add("-- Attributes:"); for _, s in ipairs(r.attrs) do add(s) end
		add("-- Values:"); for _, s in ipairs(r.values) do add(s) end
		add("-- Scripts:"); for _, s in ipairs(r.scripts) do add(s) end
		add("-- Remotes:"); for _, s in ipairs(r.remotes) do add(s) end
		return table.concat(lines, "\n")
	end

	local function showScan(r)
		if not r then
			for _, row in ipairs({infoVehicle, infoHand, infoGear, infoRPM, infoTrans}) do row:Set("-") end
			return
		end
		infoVehicle:Set(string.format("%s (%s)", r.model and r.model.Name:sub(1, 14) or "?", r.seat.ClassName))
		infoHand:Set(r.hand and ("Yes: " .. r.hand.name:sub(1, 14)) or UI:tr("Not found"))
		infoGear:Set(r.gear and r.gear.name:sub(1, 18) or UI:tr("Not found"))
		infoRPM:Set(r.rpm and r.rpm.name:sub(1, 18) or UI:tr("Not found"))
		infoTrans:Set(r.trans and r.trans.name:sub(1, 18) or UI:tr("Not found"))
	end

	local function updateLive()
		if not det then return end
		if det.gear then local ok, v = pcall(det.gear.get); if ok then infoGear:Set("Gear " .. tostring(v)) end end
		if det.rpm then local ok, v = pcall(det.rpm.get); if ok and type(v) == "number" then infoRPM:Set(tostring(math.floor(v))) end end
		if det.trans then local ok, v = pcall(det.trans.get); if ok then infoTrans:Set(tostring(v)) end end
	end

	-- ===== gearbox switch =====
	local function gearNow()
		if det and det.gear then
			local ok, g = pcall(det.gear.get)
			if ok and type(g) == "number" then return g end
		end
		return internalGear
	end

	local function shift(dir)
		if shifting then return end
		shifting = true
		lastShift = os.clock()
		task.spawn(function()
			local key = dir > 0 and keys.ShiftUp or keys.ShiftDown
			if transMode == "Manual" then
				setKey(keys.Clutch, true); task.wait(0.15)
				tap(key, 0.06); task.wait(0.15)
				setKey(keys.Clutch, false)
			else
				tap(key, 0.06)
				task.wait(0.1)
			end
			internalGear = math.max(1, internalGear + dir)
			shifting = false
		end)
	end

	local function autoShift(speed)
		if transMode == "Automatic" or shifting or os.clock() - lastShift < 0.6 then return end
		local gear = gearNow()
		local rpm
		if det and det.rpm then
			local ok, v = pcall(det.rpm.get)
			if ok and type(v) == "number" then rpm = v end
		end
		if rpm then
			if rpm > upRPM and gear < 8 then shift(1)
			elseif rpm < downRPM and gear > 1 and speed > 8 then shift(-1) end
		else
			local top = 6 -- No data RPM
			local want = math.clamp(math.floor(speed / (maxSpeed / top)) + 1, 1, top)
			if want > gear then shift(1) elseif want < gear and gear > 1 then shift(-1) end
		end
	end

	-- ===== UI =====
	local section = page:addSection("Auto Drive")
	section:addToggle("Enabled", false, function(v)
		if v then
			if inputMode == "Keyboard" and not VIM then
				UI:notify("Keyboard input not supported, using Seat", "info")
				inputMode = "Seat"
			end
			handChecked = false
			steer, steerTarget, nextChange = 0, 0, 0
		else
			releaseInputs()
		end
		enabled = v
	end)
	local inputDrop = section:addDropdown("Input Method", {"Keyboard", "Seat"}, function(name) inputMode = name end)
	inputDrop:Set("Keyboard")
	local throttleSlider = section:addSlider("Throttle (%)", 60, 10, 100, function(v) throttlePct = v end, "%")
	local speedSlider = section:addSlider("Max Speed (studs/s)", 60, 20, 200, function(v) maxSpeed = v end)
	local steerSlider = section:addSlider("Max Steer (%)", 70, 10, 100, function(v) maxSteerPct = v end, "%")
	local intervalSlider = section:addSlider("Steer Change Interval (s)", 3, 1, 10, function(v) changeEvery = v end)
	section:addButton("Reset Auto Drive", function()
		throttleSlider:Set(60); speedSlider:Set(60); steerSlider:Set(70); intervalSlider:Set(3)
		UI:notify("Auto Drive reset", "success")
	end)
	section:addLabel("Drives the vehicle you are in by itself: random turns, avoids obstacles, reverses when stuck. Holding W/A/S/D pauses it. Use Seat input only if Keyboard does not work.")

	local transSection = page:addSection("Transmission")
	local transDrop = transSection:addDropdown("Transmission Mode", {"Automatic", "Semi (DCT)", "Manual"}, function(name)
		transMode = name:find("Semi") and "Semi" or name
	end)
	transDrop:Set("Automatic")
	local upSlider = transSection:addSlider("Upshift RPM", 6000, 2000, 9000, function(v) upRPM = v end)
	local downSlider = transSection:addSlider("Downshift RPM", 2500, 1000, 6000, function(v) downRPM = v end)
	transSection:addKeybind("Shift Up Key", keys.ShiftUp, nil, function(i) keys.ShiftUp = i.KeyCode end)
	transSection:addKeybind("Shift Down Key", keys.ShiftDown, nil, function(i) keys.ShiftDown = i.KeyCode end)
	transSection:addKeybind("Clutch Key", keys.Clutch, nil, function(i) keys.Clutch = i.KeyCode end)
	transSection:addKeybind("Handbrake Key", keys.Handbrake, nil, function(i) keys.Handbrake = i.KeyCode end)
	transSection:addLabel("Automatic: the car shifts itself. Semi (DCT): shifts up/down with the shift keys, no clutch. Manual: holds the clutch key for each shift. Set the keys to match the car, and pick the mode the car is currently in. Without RPM data, shifts are estimated from speed.")

	local scanSection = page:addSection("Vehicle Scan")
	infoVehicle = scanSection:addInfo("Vehicle", "-")
	infoHand = scanSection:addInfo("Handbrake", "-")
	infoGear = scanSection:addInfo("Gear", "-")
	infoRPM = scanSection:addInfo("RPM", "-")
	infoTrans = scanSection:addInfo("Transmission", "-")
	scanSection:addButton("Scan Vehicle", function()
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildWhichIsA("Humanoid")
		local seat = h and h.SeatPart
		if not seat then
			UI:notify("Sit in a vehicle first", "error")
			return
		end
		scannedSeat, det = seat, scan(seat)
		showScan(det)
	end)
	scanSection:addButton("Save Scan to File", function()
		if not det then
			UI:notify("Sit in a vehicle first", "error")
			return
		end
		local text = dumpScan(det)
		print(text)
		local ok = writefile and pcall(writefile, "xxg-vehicle.txt", text)
		UI:notify(ok and "Scan saved to xxg-vehicle.txt" or "Failed to save scan", ok and "success" or "error")
	end)

	-- Loop
	local function clearance(seat, dir, range)
		local origin = seat.Position + Vector3.new(0, 1, 0)
		local result = workspace:Raycast(origin, dir * range, rayParams)
		if not result or result.Normal.Y > 0.7 then return range end 
		return (result.Position - origin).Magnitude
	end

	local conn = RunService.Stepped:Connect(function(_, dt)
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildWhichIsA("Humanoid")
		local seat = h and h.SeatPart
		if not seat then
			if scannedSeat then scannedSeat, det, currentSeat = nil, nil, nil; showScan(nil) end
			releaseAll()
			steer, steerTarget = 0, 0
			return
		end
		currentSeat = seat
		if seat ~= scannedSeat then
			scannedSeat, det, handChecked = seat, scan(seat), false
			showScan(det)
		end
		refreshTimer = refreshTimer + dt
		if refreshTimer > 0.5 then refreshTimer = 0; updateLive() end

		if not enabled then return end
		if UserInputService:GetFocusedTextBox() or manualInput() then
			releaseAll()
			return
		end

		pcall(function()
			rayParams.FilterDescendantsInstances = {det and det.model or seat, c}
			local useKeys = (inputMode == "Keyboard") and VIM ~= nil
			local now = os.clock()
			local fwd, right = seat.CFrame.LookVector, seat.CFrame.RightVector
			local speed = seat.AssemblyLinearVelocity.Magnitude
			local look = 12 + speed * 0.5
			local steerMax = maxSteerPct / 100
			local throttle = throttlePct / 100

			if now < reverseUntil then
				throttle = -0.6 
			elseif clearance(seat, fwd, look) < look * 0.7 then
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

			-- Stuck detection
			if throttle > 0 and speed < 2 and now > reverseUntil and not shifting then
				stuckTime = stuckTime + dt
				if stuckTime > 3 then
					reverseUntil = now + 1.4
					steerTarget = (math.random() < 0.5 and -1 or 1) * steerMax
					stuckTime = 0
				end
			else
				stuckTime = 0
			end

			steer = steer + math.clamp(steerTarget - steer, -dt * 1.5, dt * 1.5)
			if throttle > 0 and speed > maxSpeed then throttle = 0 end

			if useKeys then
				if not handChecked then
					handChecked = true
					if det and det.hand then
						local ok, v = pcall(det.hand.get)
						if ok and (v == true or (type(v) == "number" and v ~= 0)) then
							task.spawn(tap, keys.Handbrake, 0.08) -- Release handbrake
						end
					end
				end
				autoShift(speed)
				if shifting and transMode == "Manual" and throttle > 0 then throttle = 0 end
				phase = (phase + dt) % 0.25
				local duty = phase / 0.25
				setKey(K.W, throttle > 0 and throttle > duty)
				setKey(K.S, throttle < 0)
				setKey(K.D, steer > 0 and steer > duty)
				setKey(K.A, steer < 0 and -steer > duty)
			else
				setSeatInputs(seat, throttle, steer)
			end
		end)
	end)

	ctx.modules.autodrive = {
		collect = function()
			return {throttle = throttlePct, maxSpeed = maxSpeed, maxSteer = maxSteerPct, interval = changeEvery,
				upRPM = upRPM, downRPM = downRPM}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			throttleSlider:Set(num(d.throttle, 60)); speedSlider:Set(num(d.maxSpeed, 60))
			steerSlider:Set(num(d.maxSteer, 70)); intervalSlider:Set(num(d.interval, 3))
			upSlider:Set(num(d.upRPM, 6000)); downSlider:Set(num(d.downRPM, 2500))
		end,
		prepareClose = function() enabled = false end,
		shutdown = function()
			enabled = false
			releaseInputs()
			conn:Disconnect()
		end,
	}
end