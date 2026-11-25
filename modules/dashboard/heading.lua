return {order = 10, build = function(ctx, tab)
	local UI = ctx.UI
	local name = game:GetService("Players").LocalPlayer.DisplayName
	local heading = tab:addHeading("Overview", "Dashboard", ctx.dyn("welcome", name))
	UI:onLanguage(function() heading.Subtitle.Text = ctx.dyn("welcome", name) end)
end}