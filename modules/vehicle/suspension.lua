return {order = 50, build = function(ctx, tab)
	local UI, V = ctx.UI, ctx.vehicle
	local H = V.h
	local section = tab:addSection("Suspension")

	-- {Front Stiffness, Rear Stiffness, Damping Front, Damping Rear}
	local presets = {
		Soft   = {60, 60, 80, 80},
		Normal = {100, 100, 100, 100},
		Sport  = {160, 170, 140, 150},
		Stiff  = {250, 250, 200, 200},
		Drag   = {70, 220, 90, 180},
		Drift  = {140, 80, 120, 90},
	}
	H.ui.suspPreset = section:addDropdown("Preset", {"Soft", "Normal", "Sport", "Stiff", "Drag", "Drift"}, function(name)
		local p = presets[name]
		if not p then return end
		H.applying = true
		H.ui.stiffF:Set(p[1]); H.ui.stiffR:Set(p[2]); H.ui.dampF:Set(p[3]); H.ui.dampR:Set(p[4])
		H.applying = false
	end)
	local function custom()
		if not H.applying then H.ui.suspPreset:Set("Custom") end
	end
	H.ui.stiffF = section:addSlider("Front Stiffness", 100, 25, 400, function(v) H.stiffF = v; custom() end, "%")
	H.ui.stiffR = section:addSlider("Rear Stiffness", 100, 25, 400, function(v) H.stiffR = v; custom() end, "%")
	H.ui.dampF = section:addSlider("Front Damping", 100, 25, 400, function(v) H.dampF = v; custom() end, "%")
	H.ui.dampR = section:addSlider("Rear Damping", 100, 25, 400, function(v) H.dampR = v; custom() end, "%")
	local swapToggle = section:addToggle("Swap Front / Rear", false, function(v)
		H.swap = v
		H.restore() 
	end)

	local function reset()
		H.applying = true
		H.ui.stiffF:Set(100); H.ui.stiffR:Set(100); H.ui.dampF:Set(100); H.ui.dampR:Set(100)
		H.applying = false
		H.ui.suspPreset:Set("Normal")
	end
	section:addButton("Reset Suspension", function()
		reset()
		UI:notify("Suspension reset", "success")
	end)
	V.resetters.suspension = reset

	ctx.modules["vehicle.suspension"] = {
		collect = function()
			return {suspStiffF = H.stiffF, suspStiffR = H.stiffR, suspDampF = H.dampF, suspDampR = H.dampR, swapAxles = H.swap}
		end,
		apply = function(d)
			local function num(v, def) return type(v) == "number" and v or def end
			H.applying = true
			H.ui.stiffF:Set(num(d.suspStiffF, 100)); H.ui.stiffR:Set(num(d.suspStiffR, 100))
			H.ui.dampF:Set(num(d.suspDampF, 100)); H.ui.dampR:Set(num(d.suspDampR, 100))
			H.applying = false
			H.ui.suspPreset:Set("Custom")
			if type(d.swapAxles) == "boolean" then swapToggle:Set(d.swapAxles) end
		end,
	}
end}