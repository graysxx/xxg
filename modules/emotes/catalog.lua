return {order = 40, build = function(ctx, tab)
	local E = ctx.emotes
	local SEARCH_DELAY = 0.3

	local section = tab:addSection("Emote Catalog")
	local runSearch
	local searchBox = section:addTextBox("Search", "Enter keyword", function(_, enter)
		if enter and runSearch then runSearch(false) end
	end)
	local grid = section:addGrid(240)
	local pages, busy, pending = nil, false, false

	local tb = searchBox.Instance and searchBox.Instance:FindFirstChildWhichIsA("TextBox", true)
	if tb then
		local stamp = 0
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			stamp = stamp + 1
			local mine = stamp
			task.delay(SEARCH_DELAY, function()
				if mine == stamp and runSearch then runSearch(false) end
			end)
		end)
	end

	local function addItems(items)
		for _, item in ipairs(items) do
			local id = tonumber(item.Id or item.id)
			local name = item.Name or item.name or tostring(id)
			if id then E.addEntry(grid, id, name) end
		end
	end

	runSearch = function(append)
		if busy then
			if not append then pending = true end
			return
		end
		if append and (not pages or pages.IsFinished) then return end
		busy = true
		if not append then
			grid:Clear()
			grid:SetStatus("Loading...")
		end
		local ok, err = pcall(function()
			if append then
				pages:AdvanceToNextPageAsync()
				addItems(pages:GetCurrentPage())
			else
				local params = CatalogSearchParams.new()
				params.SearchKeyword = searchBox:Get()
				params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
				pcall(function() params.Limit = 30 end)
				pages = game:GetService("AvatarEditorService"):SearchCatalog(params)
				local items = pages:GetCurrentPage()
				addItems(items)
				grid:SetStatus(#items == 0 and "No emotes found" or "")
			end
		end)
		if not ok then
			if not append then pages = nil end
			grid:SetStatus("Failed to load catalog")
			warn("[ControlPanel] catalog emote: " .. tostring(err))
		end
		busy = false
		if pending then
			pending = false
			runSearch(false)
		end
	end

	section:addButton("Load More", function() runSearch(true) end)
	task.spawn(function() runSearch(false) end)
end}