return {order = 30, build = function(ctx, tab)
	local UI = ctx.UI
	local RunService = game:GetService("RunService")
	local enabled, value, orig = false, 196, workspace.Gravity

	local section = tab:addSection("Gravity")
	section:addToggle("Enabled", false, function(v)
		if v and not enabled then orig = workspace.Gravity end
		enabled = v
		if not v then workspace.Gravity = orig end
	end)
	local slider = section:addSlider("Gravity Value", 196, 0, 400, function(v) value = v end)
	section:addButton("Reset Gravity", function()
		slider:Set(196)
		UI:notify("Gravity reset", "success")
	end)

	local conn = RunService.Stepped:Connect(function()
		if enabled and workspace.Gravity ~= value then workspace.Gravity = value end
	end)

	ctx.modules["player.gravity"] = {
		collect = function() return {gravity = value} end,
		apply = function(d) slider:Set(type(d.gravity) == "number" and d.gravity or 196) end,
		shutdown = function()
			if enabled then workspace.Gravity = orig end
			enabled = false
			conn:Disconnect()
		end,
	}
end}