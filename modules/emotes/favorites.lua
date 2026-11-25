return {order = 20, build = function(ctx, tab)
	local E = ctx.emotes
	local section = tab:addSection("Favorite Emotes")
	local grid = section:addGrid(150)

	E.refreshFavorites = function()
		grid:Clear()
		for _, f in ipairs(E.favList) do E.addEntry(grid, f.id, f.name) end
		grid:SetStatus(#E.favList == 0 and "No favorites yet" or "")
	end
	E.refreshFavorites()
end}