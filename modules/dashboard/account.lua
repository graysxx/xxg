return {order = 30, build = function(ctx, tab)
	local LocalPlayer = game:GetService("Players").LocalPlayer
	tab:addAccountCard({
		UserId = LocalPlayer.UserId, Name = LocalPlayer.Name,
		DisplayName = LocalPlayer.DisplayName, Status = "Active",
	})
	-- Minimize Profile
	ctx.UI:setMiniProfile({UserId = LocalPlayer.UserId, Name = LocalPlayer.Name, DisplayName = LocalPlayer.DisplayName})
end}