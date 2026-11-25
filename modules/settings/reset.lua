return {order = 50, build = function(ctx, tab)
	local UI, S = ctx.UI, ctx.settings
	local section = tab:addSection("Reset")
	section:addButton("Reset Settings", function()
		for _, fn in ipairs(S.resetters) do pcall(fn) end
		UI:notify("Settings reset", "success")
	end)
	section:addLabel("Resets keybinds, color theme, and background transparency to their defaults.")
end}