return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local LocalPlayer = Players.LocalPlayer

	local SEARCH_DELAY = 0.3 

	local page = UI:addPage("Emotes")
	ctx.pages.Emotes = page

	local keepMoving, loopEmote = false, false
	local activeTrack, trackDirect, stopped, lastPos = nil, false, true, 0

	local function humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	local function animatorOf(h)
		return h and h:FindFirstChildWhichIsA("Animator")
	end
	local function thumb(id)
		return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150"
	end

	-- ===== favorit =====
	local FAV_DIR = (ctx.Cfg and ctx.Cfg.ConfigFolder) or "ProjectControlPanel"
	local FAV_FILE = FAV_DIR .. "/emote-favorites.json"
	local favList = {}  
	local painters = {} 

	local function loadFavs()
		if not (isfile and readfile) then return end
		local ok, data = pcall(function()
			if isfile(FAV_FILE) then return HttpService:JSONDecode(readfile(FAV_FILE)) end
		end)
		if ok and type(data) == "table" then
			for _, e in ipairs(data) do
				if type(e) == "table" and tonumber(e.id) then
					table.insert(favList, {id = tonumber(e.id), name = tostring(e.name or e.id)})
				end
			end
		end
	end

	local function saveFavs()
		if not writefile then return end
		pcall(function()
			if makefolder and isfolder and not isfolder(FAV_DIR) then makefolder(FAV_DIR) end
			writefile(FAV_FILE, HttpService:JSONEncode(favList))
		end)
	end

	local function isFav(id)
		for _, f in ipairs(favList) do if f.id == id then return true end end
		return false
	end
	loadFavs()

	-- ===== load emote =====
	local function isAction(p)
		return p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2
			or p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4
	end

	local function stopEmote()
		stopped = true
		if activeTrack then pcall(function() activeTrack:Stop(0.15) end); activeTrack = nil end
		trackDirect = false
		local animator = animatorOf(humanoid())
		if animator then
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
				if isAction(t.Priority) then pcall(function() t:Stop(0.15) end) end
			end
		end
	end

	local function playDirect(id)
		local animator = animatorOf(humanoid())
		if not animator then return nil end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(id)
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if not ok or not track then return nil end
		pcall(function()
			track.Priority = Enum.AnimationPriority.Action4
			if loopEmote then track.Looped = true end
		end)
		track:Play(0.15)
		local t0 = os.clock()
		while track.Length == 0 and os.clock() - t0 < 1 do task.wait(0.05) end
		if track.Length == 0 then
			pcall(function() track:Stop() end)
			return nil
		end
		return track
	end

	local function playViaSystem(id, name)
		local h = humanoid()
		if not h then return nil end
		if name then
			local animator = animatorOf(h)
			local before = {}
			if animator then for _, t in ipairs(animator:GetPlayingAnimationTracks()) do before[t] = true end end
			local ok, played = pcall(function() return h:PlayEmote(name) end)
			if ok and played then
				task.wait(0.15)
				if animator then
					for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
						if not before[t] then
							pcall(function()
								t.Priority = Enum.AnimationPriority.Action4
								if loopEmote then t.Looped = true end
							end)
							return t
						end
					end
				end
				return true
			end
		end
		local ok, success, track = pcall(function() return h:PlayEmoteAndGetAnimTrackById(id) end)
		if ok and success then
			if track then
				pcall(function()
					track.Priority = Enum.AnimationPriority.Action4
					if loopEmote then track.Looped = true end
				end)
				return track
			end
			return true
		end
		return nil
	end

	local function playEmote(id, name)
		stopEmote()
		local track, direct = nil, false
		if keepMoving or loopEmote then
			track = playDirect(id) 
			direct = track ~= nil
			track = track or playViaSystem(id, name)
		else
			track = playViaSystem(id, name) 
			if not track then
				track = playDirect(id)
				direct = track ~= nil
			end
		end
		if not track then
			UI:notify("Failed to play emote", "error")
			return
		end
		stopped = false
		trackDirect = direct
		activeTrack = (typeof(track) == "Instance") and track or nil
		lastPos = 0
	end

	local keepConn = RunService.Heartbeat:Connect(function()
		if stopped or not activeTrack then return end

		if not keepMoving and trackDirect then
			local h = humanoid()
			if h then
				local st = h:GetState()
				if h.MoveDirection.Magnitude > 0.1 or st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
					stopEmote()
					return
				end
			end
		end

		if activeTrack.IsPlaying then
			lastPos = activeTrack.TimePosition
			return
		end
		local finished = activeTrack.Length > 0 and lastPos >= activeTrack.Length - 0.2
		if finished and not loopEmote then
			stopped, activeTrack = true, nil 
		elseif keepMoving then
			pcall(function()
				activeTrack.Priority = Enum.AnimationPriority.Action4
				if loopEmote then activeTrack.Looped = true end
				activeTrack:Play(0.15)
			end)
		else
			stopped, activeTrack = true, nil
		end
	end)
	local charConn = LocalPlayer.CharacterAdded:Connect(function()
		activeTrack, stopped, trackDirect = nil, true, false
	end)

	local refreshFavorites
	local favGrid

	local function setFavorite(id, name, on)
		local idx
		for i, f in ipairs(favList) do
			if f.id == id then idx = i; break end
		end
		if on and not idx then
			table.insert(favList, {id = id, name = name})
		elseif not on and idx then
			table.remove(favList, idx)
		end
		saveFavs()
		local list = painters[id]
		if list then
			for i = #list, 1, -1 do
				if not list[i](on) then table.remove(list, i) end
			end
		end
		task.defer(refreshFavorites)
	end

	local function addEntry(grid, id, name)
		local _, paint = grid:Add(thumb(id), name, function() playEmote(id, name) end, {
			on = isFav(id),
			onToggle = function(state) setFavorite(id, name, state) end,
		})
		if paint then
			painters[id] = painters[id] or {}
			table.insert(painters[id], paint)
		end
	end

	-- ----- Emote Options -----
	local optSection = page:addSection("Emote Options")
	optSection:addToggle("Keep Emote While Moving", false, function(v) keepMoving = v end)
	optSection:addToggle("Loop Emote", false, function(v)
		loopEmote = v
		if v and activeTrack then pcall(function() activeTrack.Looped = true end) end
	end)
	optSection:addButton("Stop Emote", stopEmote)

	-- ----- Favorite Emotes -----
	local favSection = page:addSection("Favorite Emotes")
	favGrid = favSection:addGrid(150)
	refreshFavorites = function()
		favGrid:Clear()
		for _, f in ipairs(favList) do addEntry(favGrid, f.id, f.name) end
		favGrid:SetStatus(#favList == 0 and "No favorites yet" or "")
	end
	refreshFavorites()

	-- ----- My Emotes -----
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
			if tonumber(id) then
				n += 1
				addEntry(myGrid, tonumber(id), name)
			end
		end
		myGrid:SetStatus(n == 0 and "No equipped emotes found" or "")
	end
	mySection:addButton("Refresh My Emotes", loadMine)

	-- ----- Emote Catalog -----
	local catSection = page:addSection("Emote Catalog")
	local runSearch
	local searchBox = catSection:addTextBox("Search", "Enter keyword", function(_, enter)
		if enter and runSearch then runSearch(false) end
	end)
	local catGrid = catSection:addGrid(240)
	local pages, busy, pending = nil, false, false

	local tb = searchBox.Instance and searchBox.Instance:FindFirstChildWhichIsA("TextBox", true)
	if tb then
		local stamp = 0
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			stamp += 1
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
			if id then addEntry(catGrid, id, name) end
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
			catGrid:Clear()
			catGrid:SetStatus("Loading...")
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
				catGrid:SetStatus(#items == 0 and "No emotes found" or "")
			end
		end)
		if not ok then
			if not append then pages = nil end
			catGrid:SetStatus("Failed to load catalog")
			warn("[ControlPanel] catalog emote: " .. tostring(err))
		end
		busy = false
		if pending then
			pending = false
			runSearch(false)
		end
	end

	catSection:addButton("Load More", function() runSearch(true) end)

	-- ----- Play by ID -----
	local idSection = page:addSection("Play by ID")
	local function playFromText(text)
		local id = tonumber((tostring(text):gsub("%D", "")))
		if not id then
			UI:notify("Invalid emote ID", "error")
			return
		end
		playEmote(id, nil)
	end
	local idBox = idSection:addTextBox("Emote ID", "Enter Emote ID", function(text, enter)
		if enter then playFromText(text) end
	end)
	idSection:addButton("Play Emote ID", function() playFromText(idBox:Get()) end)

	task.spawn(function()
		local t0 = os.clock()
		while not humanoid() and os.clock() - t0 < 5 do task.wait(0.1) end
		loadMine()
	end)
	task.spawn(function() runSearch(false) end)

	ctx.modules.emotes = {
		shutdown = function()
			stopEmote()
			keepConn:Disconnect()
			charConn:Disconnect()
		end,
	}
end