return {order = 10, build = function(ctx, tab)
	local UI, P = ctx.UI, ctx.player
	local RunService = game:GetService("RunService")
	local enabled, value = false, 16

	local section = tab:addSection("Walk Speed")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then P.restoreWalk() end
	end)
	local slider = section:addSlider("Speed", 16, 0, 300, function(v) value = v end)
	section:addButton("Reset Walk Speed", function()
		slider:Set(16)
		UI:notify("Walk Speed reset", "success")
	end)

	local conn = RunService.Stepped:Connect(function()
		if not enabled then return end
		local h = P.humanoid()
		if h then
			P.remember(h)
			if h.WalkSpeed ~= value then h.WalkSpeed = value end
		end
	end)

	ctx.modules["player.walkspeed"] = {
		collect = function() return {walkSpeed = value} end,
		apply = function(d) slider:Set(type(d.walkSpeed) == "number" and d.walkSpeed or 16) end,
		shutdown = function()
			enabled = false
			P.restoreWalk()
			conn:Disconnect()
		end,
	}
end}