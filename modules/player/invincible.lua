return {order = 48, build = function(ctx, tab)
	local P = ctx.player
	local RunService = game:GetService("RunService")
	local enabled = false

	local section = tab:addSection("Invincible")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then
			local h = P.humanoid()
			if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end) end
		end
	end)
	section:addLabel("Keeps your health full and blocks the dead state on your side. It cannot stop damage the game's server applies itself, so it only works in games that use normal Humanoid health.")

	local conn = RunService.Heartbeat:Connect(function()
		if not enabled then return end
		local h = P.humanoid()
		if not h then return end
		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			h.BreakJointsOnDeath = false
			if h.Health < h.MaxHealth then h.Health = h.MaxHealth end
		end)
	end)

	ctx.modules["player.invincible"] = {
		shutdown = function()
			if enabled then
				local h = P.humanoid()
				if h then pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end) end
			end
			enabled = false
			conn:Disconnect()
		end,
	}
end}