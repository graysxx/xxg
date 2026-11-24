return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer
	local page = ctx.pages.Misc or UI:addPage("Misc")

	local ordered = {}              
	local listNames, byLabel = {}, {}
	local spectating
	local info, drop

	local function labelOf(p) return p.DisplayName .. " (@" .. p.Name .. ")" end

	local function rebuild(exclude)
		table.clear(ordered); table.clear(listNames); table.clear(byLabel)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p ~= exclude then table.insert(ordered, p) end
		end
		table.sort(ordered, function(a, b) return a.Name:lower() < b.Name:lower() end)
		for _, p in ipairs(ordered) do
			local label = labelOf(p)
			table.insert(listNames, label)
			byLabel[label] = p
		end
	end
	rebuild()

	local function humanoidOf(p)
		local c = p and p.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end

	local function setSubject(h)
		local cam = workspace.CurrentCamera
		if cam and h then cam.CameraSubject = h end
	end

	local function stop(silent)
		spectating = nil
		info:Set(UI:tr("None"))
		drop:Set("")
		setSubject(humanoidOf(LocalPlayer))
		if not silent then UI:notify("Spectate stopped", "success") end
	end

	local function start(p)
		if not p then return end
		spectating = p
		info:Set(p.DisplayName)
		drop:Set(labelOf(p))
		setSubject(humanoidOf(p))
	end

	local function step(dir)
		if #ordered == 0 then
			UI:notify("No other players", "error")
			return
		end
		local idx = table.find(ordered, spectating)
		if not idx then idx = (dir > 0) and 0 or 1 end
		idx = ((idx - 1 + dir) % #ordered) + 1
		start(ordered[idx])
	end

	local section = page:addSection("Spectate")
	drop = section:addDropdown("Select Player", listNames, function(label) start(byLabel[label]) end)
	info = section:addInfo("Spectating", UI:tr("None"))
	section:addButton("Previous Player", function() step(-1) end)
	section:addButton("Next Player", function() step(1) end)
	section:addButton("Exit Spectate", function()
		if spectating then stop() end
	end)

	-- Camera subject update
	local camConn = RunService.RenderStepped:Connect(function()
		if not spectating then return end
		local h = humanoidOf(spectating)
		local cam = workspace.CurrentCamera
		if h and cam and cam.CameraSubject ~= h then cam.CameraSubject = h end
	end)

	local addedConn = Players.PlayerAdded:Connect(function() rebuild() end)
	local removingConn = Players.PlayerRemoving:Connect(function(p)
		if p == spectating then
			local idx = table.find(ordered, p) or 1
			rebuild(p)
			spectating = nil
			if #ordered > 0 then
				start(ordered[math.min(idx, #ordered)])
				UI:notify("Spectated player left, switched to next", "info")
			else
				stop(true)
			end
		else
			rebuild(p)
		end
	end)

	ctx.modules.spectate = {
		shutdown = function()
			if spectating then stop(true) end
			camConn:Disconnect(); addedConn:Disconnect(); removingConn:Disconnect()
		end,
	}
end