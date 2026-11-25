return {order = 30, build = function(ctx, tab)
	local UI, S = ctx.UI, ctx.settings
	local section = tab:addSection("Language")
	local default = table.find(UI.Languages, S.language) and S.language or "English"

	local drop = section:addDropdown("Language", UI.Languages, function(name)
		UI:setLanguage(name)
	end)
	drop:Set(default)

	table.insert(S.resetters, function()
		drop:Set(default)
		UI:setLanguage(default)
	end)
end}