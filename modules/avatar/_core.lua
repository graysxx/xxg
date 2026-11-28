return {order = 0, page = false, build = function(ctx)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local A = {}
	ctx.avatar = A

	function A.character() return LocalPlayer.Character end
	function A.humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	function A.short(err)
		return (tostring(err):gsub("^.-:%d+:%s*", "")):sub(1, 70)
	end

	-- A.original = avatar asli akunmu (cadangan untuk Reset); A.desc = deskripsi kerja yang diedit
	A.original, A.desc = nil, nil
	task.spawn(function()
		local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId) end)
		if ok and desc then
			A.original = desc
			A.desc = desc:Clone()
		end
	end)

	local function unanchor(inst)
		if inst:IsA("BasePart") then inst.Anchored = false end
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then d.Anchored = false end
		end
	end
	local function isWeld(d)
		return d:IsA("Weld") or d:IsA("Motor6D") or d:IsA("WeldConstraint")
	end

	-- pasang aksesori dengan las sendiri (termasuk layered clothing)
	function A.attach(acc)
		local c = A.character()
		local handle = acc:FindFirstChild("Handle")
		if not (c and handle) then return false end

		local part0, c0, c1
		for _, d in ipairs(handle:GetChildren()) do
			if d:IsA("JointInstance") and d.Part0 then
				part0 = c:FindFirstChild(d.Part0.Name)
				if part0 then c0, c1 = d.C0, d.C1 end
				break
			end
		end
		if not part0 then
			local hAtt = handle:FindFirstChildOfClass("Attachment")
			if hAtt then
				for _, p in ipairs(c:GetChildren()) do
					if p:IsA("BasePart") then
						local a = p:FindFirstChild(hAtt.Name)
						if a and a:IsA("Attachment") then
							part0, c0, c1 = p, a.CFrame, hAtt.CFrame
							break
						end
					end
				end
			end
		end
		if not part0 then
			local layered = handle:FindFirstChildOfClass("WrapLayer") ~= nil
			part0 = (layered and (c:FindFirstChild("LowerTorso") or c:FindFirstChild("Torso")))
				or c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
			c0, c1 = CFrame.new(), CFrame.new()
		end
		if not part0 then return false end

		for _, d in ipairs(handle:GetChildren()) do
			if isWeld(d) then d:Destroy() end
		end
		unanchor(acc)
		handle.CanCollide = false
		handle.Massless = true
		acc.Parent = c
		handle.CFrame = part0.CFrame * c0 * c1:Inverse()
		local w = Instance.new("Weld")
		w.Name = "AccessoryWeld"
		w.Part0, w.Part1, w.C0, w.C1 = part0, handle, c0, c1
		w.Parent = handle
		return true
	end

	local R15_PARTS = {
		"LowerTorso", "UpperTorso", "Head",
		"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
	}

	local function isLook(d)
		return d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors")
	end

	-- ganti bagian badan R15 satu per satu; bagian baru dipasang dulu, baru yang lama dihapus
	local function morphR15(c, h, model)
		local root = c:FindFirstChild("HumanoidRootPart")
		if not (root and model:FindFirstChild("UpperTorso") and c:FindFirstChild("UpperTorso")) then return false end
		local byName = {HumanoidRootPart = root}
		for _, name in ipairs(R15_PARTS) do
			local old, src = c:FindFirstChild(name), model:FindFirstChild(name)
			if old and src then
				local new = src:Clone()
				unanchor(new)
				new.CFrame = old.CFrame
				for _, m in ipairs(new:GetChildren()) do
					if m:IsA("Motor6D") then
						local p0 = m.Part0 and byName[m.Part0.Name]
						if p0 then m.Part0 = p0 end
						m.Part1 = new
					end
				end
				for _, m in ipairs(c:GetDescendants()) do -- sendi lain yang menunjuk bagian lama
					if m:IsA("Motor6D") and m.Part0 == old then m.Part0 = new end
				end
				old.Name = name .. "_old"
				new.Parent = c
				old:Destroy()
				byName[name] = new
			end
		end
		local mh = model:FindFirstChildWhichIsA("Humanoid")
		if mh then h.HipHeight = mh.HipHeight end
		local mRoot = model:FindFirstChild("HumanoidRootPart")
		if mRoot then root.Size = mRoot.Size end
		return true
	end

	-- R6: hanya kepala (mesh + wajah) yang bisa diganti; badan R6 tidak punya bentuk lain
	local function morphR6(c, model)
		local head, mhead = c:FindFirstChild("Head"), model:FindFirstChild("Head")
		if not (head and mhead) then return false end
		for _, d in ipairs(head:GetChildren()) do
			if d:IsA("SpecialMesh") or d:IsA("Decal") then d:Destroy() end
		end
		for _, d in ipairs(mhead:GetChildren()) do
			if d:IsA("SpecialMesh") or d:IsA("Decal") then d:Clone().Parent = head end
		end
		return true
	end

	function A.morph(model)
		local c, h = A.character(), A.humanoid()
		if not (c and h) then return false, "no character" end

		-- cegah karakter mati / respawn selama bagian badan diganti
		local prevNeck, prevBreak = h.RequiresNeck, h.BreakJointsOnDeath
		local prevDead = h:GetStateEnabled(Enum.HumanoidStateType.Dead)
		h.RequiresNeck, h.BreakJointsOnDeath = false, false
		h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

		local ok, err = pcall(function()
			for _, d in ipairs(c:GetChildren()) do
				if isLook(d) then d:Destroy() end
			end
			if h.RigType == Enum.HumanoidRigType.R15 then
				morphR15(c, h, model)
			else
				morphR6(c, model)
			end
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") then
					d:Clone().Parent = c
				end
			end
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("Accessory") then A.attach(d:Clone()) end
			end
		end)

		task.delay(0.6, function()
			pcall(function()
				h.RequiresNeck, h.BreakJointsOnDeath = prevNeck, prevBreak
				h:SetStateEnabled(Enum.HumanoidStateType.Dead, prevDead)
			end)
		end)
		if not ok then return false, A.short(err) end
		return true
	end

	-- bangun avatar dari HumanoidDescription lalu terapkan ke karaktermu, langsung di tempat
	function A.build(desc)
		local h = A.humanoid()
		if not (h and desc) then return false, "no character" end
		local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, h.RigType) end)
		if not ok or not model then return false, "could not build avatar: " .. A.short(model) end
		local okM, err = A.morph(model)
		model:Destroy()
		return okM, err
	end

	function A.reset()
		if not A.original then return false, "original avatar not loaded yet" end
		A.desc = A.original:Clone()
		return A.build(A.desc)
	end
end}