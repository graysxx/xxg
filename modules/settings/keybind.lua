return {order = 10, build = function(ctx, tab)
	local UI, S = ctx.UI, ctx.settings
	local section = tab:addSection("Keybinds")

	local panelKey = section:addKeybind("Toggle Panel", S.key, function()
		UI:toggle()
	end, nil, true) 

	local extras = {}
	for _, k in ipairs(ctx.keybinds) do
		table.insert(extras, {api = section:addKeybind(k.title, k.default, k.callback, nil, true), default = k.default})
	end

	table.insert(S.resetters, function()
		panelKey:Set(S.key)
		for _, e in ipairs(extras) do e.api:Set(e.default, true) end
	end)
end}