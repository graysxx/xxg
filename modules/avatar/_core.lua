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

	-- A.original = avatar asli akunmu (cadangan); A.desc = deskripsi kerja yang diedit
	A.original, A.desc = nil, nil
	task.spawn(function()
		local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId) end)
		if ok and desc then
			A.original = desc
			A.desc = desc:Clone()
		end
	end)

	-- pratinjau lokal di karaktermu (hanya terlihat olehmu)
	function A.preview()
		local h = A.humanoid()
		if not (h and A.desc) then return false, "no character or avatar not loaded yet" end
		local ok, err = pcall(function() h:ApplyDescription(A.desc) end)
		if ok then return true end
		return false, A.short(err)
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