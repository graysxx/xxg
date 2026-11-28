return {order = 10, build = function(ctx, tab)
	local name = game:GetService("Players").LocalPlayer.DisplayName
	tab:addHeading("Overview", "Dashboard", "Welcome back, " .. name .. "!")
end}