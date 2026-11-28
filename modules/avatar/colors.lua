return {order = 30, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local part = "All"
	local props = {
		Head = {"HeadColor3"}, Torso = {"TorsoColor3"},
		["Left Arm"] = {"LeftArmColor3"}, ["Right Arm"] = {"RightArmColor3"},
		["Left Leg"] = {"LeftLegColor3"}, ["Right Leg"] = {"RightLegColor3"},
	}
	local all = {"HeadColor3", "TorsoColor3", "LeftArmColor3", "RightArmColor3", "LeftLegColor3", "RightLegColor3"}
	local descFor = {
		HeadColor3 = "HeadColor", TorsoColor3 = "TorsoColor", LeftArmColor3 = "LeftArmColor",
		RightArmColor3 = "RightArmColor", LeftLegColor3 = "LeftLegColor", RightLegColor3 = "RightLegColor",
	}

	local section = tab:addSection("Body Colors")
	local drop = section:addDropdown("Body Part", {"All", "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}, function(name)
		part = name
	end)
	drop:Set("All")
	section:addColorPicker("Color", Color3.fromRGB(255, 204, 153), function(color)
		local c = A.character()
		local bc = c and c:FindFirstChildOfClass("BodyColors")
		if not bc and not A.desc then
			UI:notify("No body colors on this character", "error")
			return
		end
		for _, p in ipairs(part == "All" and all or props[part] or {}) do
			if bc then bc[p] = color end                      -- pratinjau lokal
			if A.desc then A.desc[descFor[p]] = color end     -- ikut tersimpan kalau di-save ke akun
		end
	end)
end}