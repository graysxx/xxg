return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer
	local page = ctx.pages.Misc or UI:addPage("Misc")

	local target                      -- Player yang dipilih
	local listNames, byLabel = {}, {} -- isi dropdown (diubah di tempat)
	local attachEnabled, attachMode, attachDist = false, "Back", 3
	local followEnabled, followDist = false, 8
	local targetInfo, playerDrop, attachToggle, followToggle

	local function myParts()
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildWhichIsA("Humanoid")
		return h, h and h.RootPart
	end

	local function targetRoot()
		local c = target and target.Character
		if not c then return nil end
		local h = c:FindFirstChildWhichIsA("Humanoid")
		return (h and h.RootPart) or c:FindFirstChild("HumanoidRootPart")
	end

	-- daftar pemain: "DisplayName (@Username)". Bisa dicari dengan mengetik salah satunya.
	local function rebuildList(exclude)
		table.clear(listNames)
		table.clear(byLabel)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p ~= exclude then
				local label = p.DisplayName .. " (@" .. p.Name .. ")"
				table.insert(listNames, label)
				byLabel[label] = p
			end
		end
		table.sort(listNames, function(a, b) return a:lower() < b:lower() end)
	end
	rebuildList()

	local function stopMoving()
		local h, root = myParts()
		if h and root then h:MoveTo(root.Position) end
	end

	-- ----- Target Player -----
	local targetSection = page:addSection("Target Player")
	playerDrop = targetSection:addDropdown("Select Player", listNames, function(label)
		local p = byLabel[label]
		if p then
			target = p
			targetInfo:Set(p.DisplayName)
		end
	end)
	targetInfo = targetSection:addInfo("Target", UI:tr("None"))
	targetSection:addButton("Clear Target", function()
		target = nil
		playerDrop:Set("")
		targetInfo:Set(UI:tr("None"))
		attachToggle:Set(false)
		followToggle:Set(false)
		UI:notify("Target cleared", "success")
	end)

	-- ----- Attach to Player -----
	local attachSection = page:addSection("Attach to Player")
	attachToggle = attachSection:addToggle("Enabled", false, function(v)
		if v then
			if not target then
				UI:notify("Select a player first", "error")
				attachToggle:Set(false)
				return
			end
			if followEnabled then followToggle:Set(false) end
		end
		attachEnabled = v
	end)
	local modeDrop = attachSection:addDropdown("Position", {"Back", "Above", "Left", "Right"}, function(name)
		attachMode = name
	end)
	modeDrop:Set("Back")
	local attachSlider = attachSection:addSlider("Distance (studs)", 3, 1, 10, function(v) attachDist = v end)

	local function offsetFor()
		if attachMode == "Above" then return CFrame.new(0, attachDist, 0) end
		if attachMode == "Left" then return CFrame.new(-attachDist, 0, 0) end
		if attachMode == "Right" then return CFrame.new(attachDist, 0, 0) end
		return CFrame.new(0, 0, attachDist) -- Back (karakter menghadap -Z, jadi belakang = +Z)
	end

	local attachConn = RunService.Stepped:Connect(function()
		if not attachEnabled then return end
		local h, root = myParts()
		local tRoot = targetRoot()
		if not (h and root and tRoot) or h.Health <= 0 or h.SeatPart then return end
		root.CFrame = tRoot.CFrame * offsetFor()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	-- ----- Follow Player -----
	local followSection = page:addSection("Follow Player")
	followToggle = followSection:addToggle("Enabled", false, function(v)
		if v then
			if not target then
				UI:notify("Select a player first", "error")
				followToggle:Set(false)
				return
			end
			if attachEnabled then attachToggle:Set(false) end
		else
			stopMoving()
		end
		followEnabled = v
	end)
	local followSlider = followSection:addSlider("Follow Distance (studs)", 8, 3, 40, function(v) followDist = v end)

	local lastMove, stuckTime = 0, 0
	local followConn = RunService.Heartbeat:Connect(function(dt)
		if not followEnabled then return end
		local h, root = myParts()
		local tRoot = targetRoot()
		if not (h and root and tRoot) or h.Health <= 0 or h.SeatPart then return end
		local dist = (tRoot.Position - root.Position).Magnitude
		if dist > followDist then
			if os.clock() - lastMove > 0.2 then
				lastMove = os.clock()
				h:MoveTo(tRoot.Position)
			end
			-- kalau tersangkut (hampir tidak bergerak padahal masih jauh), lompat
			local v = root.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude < 1 then stuckTime += dt else stuckTime = 0 end
			if stuckTime > 0.6 then
				h.Jump = true
				stuckTime = 0
			end
		else
			stuckTime = 0
			if os.clock() - lastMove > 0.2 then
				lastMove = os.clock()
				h:MoveTo(root.Position) -- sudah cukup dekat, berhenti
			end
		end
	end)

	-- pemain masuk / keluar
	local addedConn = Players.PlayerAdded:Connect(function() rebuildList() end)
	local removingConn = Players.PlayerRemoving:Connect(function(p)
		if p == target then
			target = nil
			targetInfo:Set(UI:tr("None"))
			playerDrop:Set("")
			attachToggle:Set(false)
			followToggle:Set(false)
			UI:notify("Target left the game", "info")
		end
		rebuildList(p)
	end)

	ctx.modules.target = {
		collect = function()
			return {attachMode = attachMode, attachDist = attachDist, followDist = followDist}
		end,
		apply = function(d)
			if type(d.attachMode) == "string" and table.find({"Back", "Above", "Left", "Right"}, d.attachMode) then
				attachMode = d.attachMode
				modeDrop:Set(d.attachMode)
			end
			if type(d.attachDist) == "number" then attachSlider:Set(d.attachDist) end
			if type(d.followDist) == "number" then followSlider:Set(d.followDist) end
		end,
		shutdown = function()
			attachEnabled, followEnabled = false, false
			stopMoving()
			attachConn:Disconnect(); followConn:Disconnect()
			addedConn:Disconnect(); removingConn:Disconnect()
		end,
	}
end