return {order = 0, page = false, build = function(ctx)
	local Players = game:GetService("Players")
	local AvatarEditorService = game:GetService("AvatarEditorService")
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

	-- A.original = avatar asli akunmu (cadangan); A.desc = deskripsi kerja (dipakai saat Save ke akun)
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

	-- pasang aksesori dengan las sendiri (Humanoid:AddAccessory tidak selalu mengelas dari sisi klien)
	function A.attach(acc)
		local c = A.character()
		local handle = acc:FindFirstChild("Handle")
		if not (c and handle) then return false end

		local part0, c0, c1
		for _, d in ipairs(handle:GetChildren()) do -- las bawaan model: ikuti posisinya, arahkan ke bagian badan kita
			if d:IsA("JointInstance") and d.Part0 then
				part0 = c:FindFirstChild(d.Part0.Name)
				if part0 then c0, c1 = d.C0, d.C1 end
				break
			end
		end
		if not part0 then -- cari attachment bernama sama di badan
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
		if not part0 then -- cadangan terakhir
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

	local PART_ORDER = {
		"LowerTorso", "UpperTorso", "Head",
		"LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
		"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot",
	}

	-- pindahkan tampilan model avatar ke karaktermu (badan, kepala, aksesori, layered clothing, pakaian)
	function A.morph(model)
		local c, h = A.character(), A.humanoid()
		if not (c and h) then return false, "no character" end
		local root = c:FindFirstChild("HumanoidRootPart")
		local mh = model:FindFirstChildWhichIsA("Humanoid")

		for _, d in ipairs(c:GetChildren()) do
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") then
				d:Destroy()
			end
		end

		local r15 = root and h.RigType == Enum.HumanoidRigType.R15
			and c:FindFirstChild("UpperTorso") and model:FindFirstChild("UpperTorso")
		if r15 then
			local byName = {HumanoidRootPart = root}
			for _, name in ipairs(PART_ORDER) do
				local old, src = c:FindFirstChild(name), model:FindFirstChild(name)
				if old and src then
					local new = src:Clone()
					unanchor(new)
					new.CFrame = old.CFrame
					for _, m in ipairs(new:GetChildren()) do -- sambungkan sendi bagian baru ke rig kita
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
			if mh then
				h.HipHeight = mh.HipHeight
				for _, nv in ipairs(mh:GetChildren()) do
					if nv:IsA("NumberValue") then
						local mine = h:FindFirstChild(nv.Name)
						if mine and mine:IsA("NumberValue") then mine.Value = nv.Value end
					end
				end
			end
			local mRoot = model:FindFirstChild("HumanoidRootPart")
			if mRoot then root.Size = mRoot.Size end
		end

		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") then
				d:Clone().Parent = c
			end
		end
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("Accessory") then A.attach(d:Clone()) end
		end
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		return true, r15 and nil or "body parts need an R15 character (clothes and accessories were applied)"
	end

	-- bangun avatar dari HumanoidDescription lalu terapkan ke karaktermu
	function A.build(desc, userId)
		local model
		local ok, res = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
		if ok then model = res end
		if not model and userId then
			local ok2, res2 = pcall(function() return Players:CreateHumanoidModelFromUserId(userId) end)
			if ok2 then model = res2 end
		end
		if not model then return false, "could not build avatar model" end
		local okM, result, note = pcall(A.morph, model)
		model:Destroy()
		if not okM then return false, A.short(result) end
		return result, note
	end

	function A.reset()
		if not A.original then return false, "original avatar not loaded yet" end
		A.desc = A.original:Clone()
		return A.build(A.original, LocalPlayer.UserId)
	end

	-- pasang satu item katalog langsung ke karakter (pratinjau lokal)
	function A.equipLocal(id)
		local c = A.character()
		if not c then return false, "no character" end
		local obj
		local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		if ok and objs then obj = objs[1] end
		if not obj then
			local ok2, model = pcall(function() return game:GetService("InsertService"):LoadAsset(id) end)
			if ok2 then obj = model end
		end
		if not obj then return false, "failed to load asset" end

		local function find(class)
			return obj:IsA(class) and obj or obj:FindFirstChildWhichIsA(class, true)
		end
		local done = false
		local acc = find("Accessory")
		if acc then
			done = A.attach(acc == obj and obj or acc:Clone())
		end
		local shirt, pants, graphic, decal = find("Shirt"), find("Pants"), find("ShirtGraphic"), find("Decal")
		if shirt then
			local s = c:FindFirstChildOfClass("Shirt") or Instance.new("Shirt")
			s.ShirtTemplate = shirt.ShirtTemplate
			s.Parent = c
			done = true
		end
		if pants then
			local p = c:FindFirstChildOfClass("Pants") or Instance.new("Pants")
			p.PantsTemplate = pants.PantsTemplate
			p.Parent = c
			done = true
		end
		if graphic then
			local g = c:FindFirstChildOfClass("ShirtGraphic") or Instance.new("ShirtGraphic")
			g.Graphic = graphic.Graphic
			g.Parent = c
			done = true
		end
		if decal and not acc then
			local head = c:FindFirstChild("Head")
			local face = head and head:FindFirstChildOfClass("Decal")
			if face then
				face.Texture = decal.Texture
				done = true
			end
		end
		if obj ~= acc then pcall(function() obj:Destroy() end) end
		return done, done and nil or "this item type cannot be previewed"
	end

	-- simpan ke akun Roblox lewat dialog resmi Roblox (hasilnya terlihat semua orang setelah respawn)
	function A.save()
		if not A.desc then return false, "avatar not loaded yet" end
		local h = A.humanoid()
		local rig = h and h.RigType or Enum.HumanoidRigType.R15
		local ok, err = pcall(function() AvatarEditorService:PromptSaveAvatar(A.desc, rig) end)
		if not ok then return false, A.short(err) end
		local okR, result = pcall(function() return AvatarEditorService.PromptSaveAvatarCompleted:Wait() end)
		if okR and result == Enum.AvatarPromptResult.Success then return true end
		return false, okR and tostring(result) or "cancelled"
	end
end}