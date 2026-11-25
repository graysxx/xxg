return {order = 40, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local H = V.h

	local section = tab:addSection("Handling Editor")
	local toggle = section:addToggle("Enabled", false, function(v)
		H.enabled = v
		if not v then H.restore() end
	end)
	section:addButton("Reset Handling", function()
		V.resetters.suspension()
		V.resetters.steering()
		UI:notify("Handling reset", "success")
	end)
	section:addLabel("Adjusts the suspension and steering of the vehicle you are driving. Original values are restored automatically when disabled, when you get out, or when you change vehicles.")

	ctx.modules["vehicle.handling"] = {
		collect = function() return {handlingEnabled = H.enabled} end,
		apply = function(d)
			if type(d.handlingEnabled) == "boolean" then toggle:Set(d.handlingEnabled) end
		end,
	}
end}