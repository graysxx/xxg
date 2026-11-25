return {order = 70, build = function(ctx, tab)
	local UI, T = ctx.UI, ctx.target
	local RunService = game:GetService("RunService")
	local enabled, followDist = false, 8
	local lastMove, stuckTime = 0, 0

	local section = tab:addSection("Follow Player")
	T.followToggle = section:addToggle("Enabled", false, function(v)
		if v then
			if not T.target then
				UI:notify("Select a player first", "error")
				T.followToggle:Set(false)
				return
			end
			if T.attachToggle then T.attachToggle:Set(false) end
		else
			local h, root = T.myParts()
			if h and root then h:MoveTo(root.Position) end
		end
		enabled = v
	end)
	local slider = section:addSlider("Follow Distance (studs)", 8, 3, 40, function(v) followDist = v end)
	table.insert(T.onClear, function() T.followToggle:Set(false) end)

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not enabled then return end
		local h, root = T.myParts()
		if not (h and root) or h.Health <= 0 or h.SeatPart then return end
		local tRoot = T.root()
		if not tRoot then T.notice("Target is too far (not loaded)") end
		local dest = tRoot and tRoot.Position or (T.lastKnown and T.lastKnown.Position)
		if not dest then return end
		local dist = (dest - root.Position).Magnitude
		if dist > followDist then
			if os.clock() - lastMove > 0.2 then
				lastMove = os.clock()
				h:MoveTo(dest)
			end
			
			local v = root.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude < 1 then stuckTime = stuckTime + dt else stuckTime = 0 end
			if stuckTime > 0.6 then
				h.Jump = true
				stuckTime = 0
			end
		else
			stuckTime = 0
			if os.clock() - lastMove > 0.2 then
				lastMove = os.clock()
				h:MoveTo(root.Position) 
			end
		end
	end)

	ctx.modules["player.follow"] = {
		collect = function() return {followDist = followDist} end,
		apply = function(d) if type(d.followDist) == "number" then slider:Set(d.followDist) end end,
		shutdown = function()
			enabled = false
			conn:Disconnect()
		end,
	}
end}