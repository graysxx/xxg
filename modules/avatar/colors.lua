return {order = 30, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local part = "All"
	local props = {
		Head = {"HeadColor3"}, Torso = {"TorsoColor3"},
		["Left Arm"] = {"LeftArmColor3"}, ["Right Arm"] = {"RightArmColor3"},
		["Left Leg"] = {"LeftLegColor3"}, ["Right Leg"] = {"RightLegColor3"},
	}
	local all = {"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"}

	local section = tab:addSection("Body Colors")
	local drop = section:addDropdown("Body Part", {"All", "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, function(name)
		part = name
	end)
	drop:Set("All")
	section:addColorPicker("Color", Color3.fromRGB(255, 204, 153), function(color)
		local c = A.character()
		local bc = c and c:FindFirstChildOfClass("BodyColors")
		if not bc then
			UI:notify("No body colors on this character", "error")
			return
		end
		for _, p in ipairs(part == "All" and all or props[part] or {}) do bc[p] = color end
	end)
end}