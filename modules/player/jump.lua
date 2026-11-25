return {order = 20, build = function(ctx, tab)
	local UI, P = ctx.UI, ctx.player
	local RunService = game:GetService("RunService")
	local enabled, value = false, 50

	local section = tab:addSection("Jump Power")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then P.restoreJump() end
	end)
	local slider = section:addSlider("Power", 50, 0, 300, function(v) value = v end)
	section:addButton("Reset Jump Power", function()
		slider:Set(50)
		UI:notify("Jump Power reset", "success")
	end)

	local conn = RunService.Stepped:Connect(function()
		if not enabled then return end
		local h = P.humanoid()
		if h then
			P.remember(h)
			if not h.UseJumpPower then h.UseJumpPower = true end
			if h.JumpPower ~= value then h.JumpPower = value end
		end
	end)

	ctx.modules["player.jump"] = {
		collect = function() return {jumpPower = value} end,
		apply = function(d) slider:Set(type(d.jumpPower) == "number" and d.jumpPower or 50) end,
		shutdown = function()
			enabled = false
			P.restoreJump()
			conn:Disconnect()
		end,
	}
end}