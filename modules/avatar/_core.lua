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

	-- simpan avatar asli supaya bisa dikembalikan
	local original
	task.spawn(function()
		local ok, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId) end)
		if ok then original = desc end
	end)

	function A.apply(desc)
		local h = A.humanoid()
		if not (h and desc) then return false, "no character" end
		return pcall(function() h:ApplyDescription(desc) end)
	end

	function A.reset()
		if not original then return false, "original avatar not loaded yet" end
		return A.apply(original)
	end
end}