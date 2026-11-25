return {order = 60, build = function(ctx, tab)
	local UI, T = ctx.UI, ctx.target
	local RunService = game:GetService("RunService")
	local enabled, mode, dist, lastChase = false, "Back", 3, 0

	local section = tab:addSection("Attach to Player")
	T.attachToggle = section:addToggle("Enabled", false, function(v)
		if v then
			if not T.target then
				UI:notify("Select a player first", "error")
				T.attachToggle:Set(false)
				return
			end
			if T.followToggle then T.followToggle:Set(false) end 
		end
		enabled = v
	end)
	local modeDrop = section:addDropdown("Position", {"Back", "Above", "Left", "Right"}, function(name) mode = name end)
	modeDrop:Set("Back")
	local slider = section:addSlider("Distance (studs)", 3, 1, 10, function(v) dist = v end)
	table.insert(T.onClear, function() T.attachToggle:Set(false) end)

	local function offset()
		if mode == "Above" then return CFrame.new(0, dist, 0) end
		if mode == "Left" then return CFrame.new(-dist, 0, 0) end
		if mode == "Right" then return CFrame.new(dist, 0, 0) end
		return CFrame.new(0, 0, dist) -- Back (-Z,  +Z)
	end

	local conn = RunService.Stepped:Connect(function()
		if not enabled then return end
		local h, root = T.myParts()
		if not (h and root) or h.Health <= 0 or h.SeatPart then return end
		local tRoot = T.root()
		if tRoot then
			root.CFrame = tRoot.CFrame * offset()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		else
			T.notice("Target is too far (not loaded)")
			if T.lastKnown and os.clock() - lastChase > 1.5 then
				lastChase = os.clock()
				root.CFrame = T.lastKnown * offset() 
			end
		end
	end)

	ctx.modules["player.attach"] = {
		collect = function() return {attachMode = mode, attachDist = dist} end,
		apply = function(d)
			if type(d.attachMode) == "string" and table.find({"Back", "Above", "Left", "Right"}, d.attachMode) then
				mode = d.attachMode
				modeDrop:Set(d.attachMode)
			end
			if type(d.attachDist) == "number" then slider:Set(d.attachDist) end
		end,
		shutdown = function()
			enabled = false
			conn:Disconnect()
		end,
	}
end}