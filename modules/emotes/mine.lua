return {order = 30, build = function(ctx, tab)
	local E = ctx.emotes
	local section = tab:addSection("My Emotes")
	local grid = section:addGrid(170)

	local function load()
		grid:Clear()
		local h = E.humanoid()
		local emotes = {}
		if h then
			local okDesc, desc = pcall(function() return h:GetAppliedDescription() end)
			if okDesc and desc then
				local ok, res = pcall(function() return desc:GetEmotes() end)
				if ok and type(res) == "table" then emotes = res end
			end
		end
		local n = 0
		for name, ids in pairs(emotes) do
			local id = type(ids) == "table" and ids[1] or ids
			if tonumber(id) then
				n = n + 1
				E.addEntry(grid, tonumber(id), name)
			end
		end
		grid:SetStatus(n == 0 and "No equipped emotes found" or "")
	end
	section:addButton("Refresh My Emotes", load)

	task.spawn(function()
		local t0 = os.clock()
		while not E.humanoid() and os.clock() - t0 < 5 do task.wait(0.1) end
		load()
	end)
end}