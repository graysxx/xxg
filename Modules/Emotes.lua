return function(ctx)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local page = UI:addPage("Emotes")
	ctx.pages.Emotes = page

	local function humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end

	local function thumb(id)
		return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
	end

	local function stopEmote()
		local h = humanoid()
		if not h then return end
		local animator = h:FindFirstChildWhichIsA("Animator")
		local tracks = animator and animator:GetPlayingAnimationTracks() or {}
		for _, t in ipairs(tracks) do pcall(function() t:Stop() end) end
	end

	local function playById(id)
		local h = humanoid()
		if not h then return false end
		local ok, success = pcall(function() return h:PlayEmoteAndGetAnimTrackById(id) end)
		return ok and success == true
	end

	-- ----- My Emotes  -----
	local mySection = page:addSection("My Emotes")
	local myGrid = mySection:addGrid(170)

	local function loadMine()
		myGrid:Clear()
		local h = humanoid()
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
			n += 1
			myGrid:Add(thumb(id), name, function()
				local h2 = humanoid()
				if not h2 then return end
				local ok, played = pcall(function() return h2:PlayEmote(name) end)
				if not (ok and played) and not playById(id) then
					UI:notify("Failed to play emote", "error")
				end
			end)
		end
		myGrid:SetStatus(n == 0 and "No equipped emotes found" or "")
	end

	mySection:addButton("Refresh My Emotes", loadMine)
	mySection:addButton("Stop Emote", stopEmote)

	-- ----- Emote Catalog -----
	local catSection = page:addSection("Emote Catalog")
	local searchBox = catSection:addTextBox("Search", "Enter keyword")
	local catGrid = catSection:addGrid(240)
	local pages, busy = nil, false

	local function addItems(items)
		for _, item in ipairs(items) do
			local id = item.Id or item.id
			local name = item.Name or item.name or tostring(id)
			if id then
				catGrid:Add(thumb(id), name, function()
					if not playById(id) then UI:notify("Failed to play emote", "error") end
				end)
			end
		end
	end

	catSection:addButton("Search Emotes", function()
		if busy then return end
		busy = true
		catGrid:Clear()
		catGrid:SetStatus("Loading...")
		local ok, err = pcall(function()
			local params = CatalogSearchParams.new()
			params.SearchKeyword = searchBox:Get()
			params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
			pcall(function() params.Limit = 30 end)
			pages = game:GetService("AvatarEditorService"):SearchCatalog(params)
			local items = pages:GetCurrentPage()
			addItems(items)
			catGrid:SetStatus(#items == 0 and "No emotes found" or "")
		end)
		if not ok then
			pages = nil
			catGrid:SetStatus("Failed to load catalog")
			warn("[ControlPanel] katalog emote: " .. tostring(err))
		end
		busy = false
	end)

	catSection:addButton("Load More", function()
		if busy or not pages or pages.IsFinished then return end
		busy = true
		local ok, err = pcall(function()
			pages:AdvanceToNextPageAsync()
			addItems(pages:GetCurrentPage())
		end)
		if not ok then
			warn("[ControlPanel] katalog emote: " .. tostring(err))
			UI:notify("Failed to load catalog", "error")
		end
		busy = false
	end)

	-- ----- Play by ID -----
	local idSection = page:addSection("Play by ID")
	local idBox = idSection:addTextBox("Emote ID", "Enter Emote ID")
	idSection:addButton("Play Emote ID", function()
		local id = tonumber((idBox:Get():gsub("%D", "")))
		if not id then
			UI:notify("Invalid emote ID", "error")
			return
		end
		if not playById(id) then UI:notify("Failed to play emote", "error") end
	end)

	task.spawn(function()
		task.wait(1)
		loadMine()
	end)

	ctx.modules.emotes = {
		shutdown = stopEmote,
	}
end