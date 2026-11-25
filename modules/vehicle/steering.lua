return {order = 60, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local H = V.h
	local section = tab:addSection("Steering")

	local presets = {Heavy = {60, 0}, Normal = {100, 0}, Light = {160, 25}, ["Very Light"] = {220, 50}, Drift = {220, 70}}
	H.ui.steerPreset = section:addDropdown("Preset", {"Heavy", "Normal", "Light", "Very Light", "Drift"}, function(name)
		local p = presets[name]
		if not p then return end
		H.applying = true
		H.ui.resp:Set(p[1]); H.ui.assist:Set(p[2])
		H.applying = false
	end)
	H.ui.resp = section:addSlider("Response", 100, 40, 250, function(v)
		H.response = v
		if not H.applying then H.ui.steerPreset:Set("Custom") end
	end, "%")
	H.ui.assist = section:addSlider("Turn Assist", 0, 0, 100, function(v)
		H.assist = v
		if not H.applying then H.ui.steerPreset:Set("Custom") end
	end, "%")

	local function reset()
		H.applying = true
		H.ui.resp:Set(100); H.ui.assist:Set(0)
		H.applying = false
		H.ui.steerPreset:Set("Normal")
	end
	section:addButton("Reset Steering", function()
		reset()
		UI:notify("Steering reset", "success")
	end)
	V.resetters.steering = reset

	ctx.modules["vehicle.steering"] = {
		collect = function() return {steerResponse = H.response, steerAssist = H.assist} end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			H.applying = true
			H.ui.resp:Set(num(d.steerResponse, 100)); H.ui.assist:Set(num(d.steerAssist, 0))
			H.applying = false
			H.ui.steerPreset:Set("Custom")
		end,
	}
end}