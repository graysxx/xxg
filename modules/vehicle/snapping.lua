return {order = 70, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local H = V.h
	local section = tab:addSection("Ground Snapping")

	local toggle = section:addToggle("Enabled", false, function(v)
		H.snapEnabled = v
		H.resetSnap()
	end)
	local strength = section:addSlider("Strength", 50, 0, 100, function(v) H.snapStrength = v end, "%")
	local range = section:addSlider("Range (studs)", 12, 4, 40, function(v) H.snapRange = v end)
	local align = section:addToggle("Align to Road", true, function(v) H.snapAlign = v end)

	local function reset()
		strength:Set(50); range:Set(12)
	end
	section:addButton("Reset Ground Snapping", function()
		reset()
		UI:notify("Ground Snapping reset", "success")
	end)
	V.resetters.snapping = reset

	ctx.modules["vehicle.snapping"] = {
		collect = function()
			return {snapEnabled = H.snapEnabled, snapStrength = H.snapStrength, snapRange = H.snapRange, snapAlign = H.snapAlign}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			strength:Set(num(d.snapStrength, 50)); range:Set(num(d.snapRange, 12))
			if type(d.snapAlign) == "boolean" then align:Set(d.snapAlign) end
			if type(d.snapEnabled) == "boolean" then toggle:Set(d.snapEnabled) end
		end,
	}
end}