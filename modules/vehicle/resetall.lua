return {order = 90, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local section = tab:addSection("Reset All")
	section:addButton("Reset All Vehicle Settings", function()
		for _, fn in pairs(V.resetters) do pcall(fn) end
		UI:notify("All vehicle values reset", "success")
	end)
	section:addLabel("Resets all values to default. Toggle positions are not changed.")
end}