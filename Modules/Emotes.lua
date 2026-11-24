return function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local LocalPlayer = Players.LocalPlayer

	local page = UI:addPage("Emotes")
	ctx.pages.Emotes = page

	local keepMoving, loopEmote = false, false
	local activeTrack, stopped = nil, true

	local trace = {}
	local function tlog(msg)
		table.insert(trace, string.format("[%.1f] %s", os.clock(), tostring(msg)))
		if #trace > 60 then table.remove(trace, 1) end
		if writefile then pcall(writefile, "xxg-emotes.txt", table.concat(trace, "\n")) end
	end

	local function humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	local function animatorOf(h)
		return h and h:FindFirstChildWhichIsA("Animator")
	end

	-- HTTP
	local function httpGet(url)
		local ok, body = pcall(function() return game:HttpGet(url) end)
		if ok and type(body) == "string" and #body > 0 then
			tlog("HttpGet OK " .. url)
			return body
		end
		tlog("HttpGet gagal " .. url .. " -> " .. tostring(body))
		local req = request or http_request or (syn and syn.request)
		if req then
			local ok2, res = pcall(req, {Url = url, Method = "GET"})
			if ok2 and res and res.Body and (res.StatusCode == nil or res.StatusCode == 200) then
				tlog("request OK " .. url)
				return res.Body
			end
			local code = ok2 and res and res.StatusCode or res
			tlog("request gagal " .. url .. " -> " .. tostring(code))
			error("HTTP " .. tostring(code))
		end
		error(tostring(body))
	end

	local thumbQueue, thumbRunning = {}, false
	local canDownload = (writefile and (getcustomasset or getsynasset)) and true or false

	local function downloadThumb(id)
		local body = httpGet("https://thumbnails.roblox.com/v1/assets?assetIds=" .. id
			.. "&returnPolicy=PlaceHolder&size=150x150&format=Png&isCircular=false")
		local data = HttpService:JSONDecode(body)
		local url = data and data.data and data.data[1] and data.data[1].imageUrl
		if not url then error("no thumbnail url") end
		local bytes = httpGet(url)
		pcall(function() if not isfolder("xxg-thumbs") then makefolder("xxg-thumbs") end end)
		local path = "xxg-thumbs/" .. id .. ".png"
		writefile(path, bytes)
		return (getcustomasset or getsynasset)(path)
	end

	local function watchThumb(label, id)
		task.delay(2.5, function()
			if not label.Parent or label.IsLoaded or not canDownload then return end
			table.insert(thumbQueue, {label = label, id = id})
			if thumbRunning then return end
			thumbRunning = true
			task.spawn(function()
				while #thumbQueue > 0 do
					local job = table.remove(thumbQueue, 1)
					if job.label.Parent and not job.label.IsLoaded then
						local ok, asset = pcall(downloadThumb, job.id)
						if ok and job.label.Parent then
							job.label.Image = asset
						elseif not ok then
							tlog("thumbnail " .. tostring(job.id) .. ": " .. tostring(asset))
						end
					end
					task.wait(0.05)
				end
				thumbRunning = false
			end)
		end)
	end

	local function addEntry(grid, id, name, onClick)
		local img = grid:Add("rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150", name, onClick)
		if img then watchThumb(img, id) end
	end

	local function isAction(p)
		return p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2
			or p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4
	end

	local function stopEmote()
		stopped = true
		if activeTrack then pcall(function() activeTrack:Stop(0.15) end); activeTrack = nil end
		local animator = animatorOf(humanoid())
		if animator then
			for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
				if isAction(t.Priority) then pcall(function() t:Stop(0.15) end) end
			end
		end
	end

	local function applyTrackSettings(track)
		pcall(function()
			track.Priority = Enum.AnimationPriority.Action4 
			track.Looped = loopEmote
		end)
	end


	local function playDirect(id)
		local animator = animatorOf(humanoid())
		if not animator then return nil end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(id)
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		if not ok or not track then return nil end
		applyTrackSettings(track)
		track:Play(0.15)
		local t0 = os.clock()
		while track.Length == 0 and os.clock() - t0 < 1.5 do task.wait(0.05) end
		if track.Length == 0 then
			pcall(function() track:Stop() end)
			return nil
		end
		return track
	end


	local function playViaSystem(id, name)
		local h = humanoid()
		if not h then return nil end
		local ok, success, track = pcall(function() return h:PlayEmoteAndGetAnimTrackById(id) end)
		if ok and success and track then
			applyTrackSettings(track)
			return track
		end
		if name then
			local animator = animatorOf(h)
			local before = {}
			if animator then for _, t in ipairs(animator:GetPlayingAnimationTracks()) do before[t] = true end end
			local ok2, played = pcall(function() return h:PlayEmote(name) end)
			if ok2 and played then
				task.wait(0.15)
				if animator then
					for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
						if not before[t] then applyTrackSettings(t); return t end
					end
				end
				return true
			end
		end
		return nil
	end

	local function playEmote(id, name)
		stopEmote()
		local track = playDirect(id) or playViaSystem(id, name)
		if not track then
			tlog("gagal memutar emote " .. tostring(id))
			UI:notify("Failed to play emote", "error")
			return
		end
		stopped = false
		activeTrack = (typeof(track) == "Instance") and track or nil
	end

	local keepConn = RunService.Heartbeat:Connect(function()
		if stopped or not keepMoving or not loopEmote or not activeTrack then return end
		if not activeTrack.IsPlaying then
			pcall(function()
				applyTrackSettings(activeTrack)
				activeTrack:Play(0.15)
			end)
		end
	end)
	local charConn = LocalPlayer.CharacterAdded:Connect(function()
		activeTrack, stopped = nil, true
	end)

	-- ===== Emote Options =====
	local optSection = page:addSection("Emote Options")
	optSection:addToggle("Keep Emote While Moving", false, function(v) keepMoving = v end)
	optSection:addToggle("Loop Emote", false, function(v) loopEmote = v end)
	optSection:addButton("Stop Emote", stopEmote)

	-- ===== My Emotes =====
	local mySection = page:addSection("My Emotes")
	local myGrid = mySection:addGrid(170)

	local function loadMine()
		local ok, err = pcall(function()
			myGrid:Clear()
			local h = humanoid()
			local emotes = {}
			if h then
				local okDesc, desc = pcall(function() return h:GetAppliedDescription() end)
				if okDesc and desc then
					local okE, res = pcall(function() return desc:GetEmotes() end)
					if okE and type(res) == "table" then emotes = res end
				end
			end
			local n = 0
			for name, ids in pairs(emotes) do
				local id = type(ids) == "table" and ids[1] or ids
				n = n + 1
				addEntry(myGrid, id, name, function() playEmote(id, name) end)
			end
			myGrid:SetStatus(n == 0 and "No equipped emotes found" or "")
		end)
		if not ok then
			tlog("loadMine: " .. tostring(err))
			myGrid:SetStatus("Failed to load emotes")
		end
	end
	mySection:addButton("Refresh My Emotes", loadMine)

	-- ===== Emote Catalog =====
	local catSection = page:addSection("Emote Catalog")
	local runSearch
	local searchBox = catSection:addTextBox("Search", "Enter keyword", function(_, enter)
		if enter and runSearch then runSearch(false) end 
	end)
	local catGrid = catSection:addGrid(240)

	local catalogBase = "https://catalog.roblox.com/v1/search/items/details"
	local variants = {
		"Category=AvatarAnimations&Subcategory=EmoteAnimations",
		"Category=12&Subcategory=39",
	}
	local activeVariant
	local pages, usingEditor, cursor, finished, lastKeyword, busy = nil, false, nil, true, "", false

	local function fetchPage(keyword, cursorValue)
		local list = activeVariant and {activeVariant} or variants
		local lastErr, sawValid = "no result", false
		for _, variant in ipairs(list) do
			local url = catalogBase .. "?" .. variant .. "&Limit=30"
			if keyword ~= "" then url = url .. "&Keyword=" .. HttpService:UrlEncode(keyword) end
			if cursorValue then url = url .. "&Cursor=" .. HttpService:UrlEncode(cursorValue) end
			local ok, body = pcall(httpGet, url)
			if ok then
				local okJ, data = pcall(function() return HttpService:JSONDecode(body) end)
				if okJ and type(data) == "table" and type(data.data) == "table" then
					sawValid = true
					if #data.data > 0 or cursorValue then
						activeVariant = variant
						return data
					end
				else
					lastErr = "bad json"
					tlog("JSON tidak valid dari " .. url)
				end
			else
				lastErr = tostring(body)
			end
		end
		if sawValid then return {data = {}} end
		error(lastErr)
	end

	-- Backup HTTP FAIL
	local function searchViaEditor(keyword)
		tlog("mencoba AvatarEditorService")
		local params = CatalogSearchParams.new()
		params.SearchKeyword = keyword
		params.AssetTypes = {Enum.AvatarAssetType.EmoteAnimation}
		pcall(function() params.Limit = 30 end)
		pages = game:GetService("AvatarEditorService"):SearchCatalog(params)
		usingEditor = true
		finished = pages.IsFinished
		local out = {}
		for _, it in ipairs(pages:GetCurrentPage()) do
			table.insert(out, {id = it.Id or it.id, name = it.Name or it.name})
		end
		return out
	end

	runSearch = function(append)
		if busy or (append and finished) then return end
		busy = true
		if not append then
			catGrid:Clear()
			catGrid:SetStatus("Loading...")
			lastKeyword = searchBox:Get()
			cursor, finished, usingEditor, pages = nil, true, false, nil
			tlog("cari: '" .. lastKeyword .. "'")
		end
		local ok, err = pcall(function()
			local items = {}
			if usingEditor then
				pages:AdvanceToNextPageAsync()
				finished = pages.IsFinished
				for _, it in ipairs(pages:GetCurrentPage()) do
					table.insert(items, {id = it.Id or it.id, name = it.Name or it.name})
				end
			else
				local okHttp, data = pcall(fetchPage, lastKeyword, append and cursor or nil)
				if okHttp then
					for _, it in ipairs(data.data) do table.insert(items, {id = it.id, name = it.name}) end
					cursor = data.nextPageCursor
					finished = (cursor == nil)
				else
					tlog("katalog HTTP gagal: " .. tostring(data))
					items = searchViaEditor(lastKeyword)
				end
			end
			for _, it in ipairs(items) do
				if it.id then
					addEntry(catGrid, it.id, it.name or tostring(it.id), function() playEmote(it.id, nil) end)
				end
			end
			tlog("hasil: " .. #items .. " item")
			catGrid:SetStatus((#items == 0 and not append) and "No emotes found" or "")
		end)
		if not ok then
			tlog("katalog gagal: " .. tostring(err))
			local reason = tostring(err):gsub("^.-:%d+:%s*", ""):sub(1, 70)
			catGrid:SetStatus("Failed to load catalog\n" .. reason)
		end
		busy = false
	end

	catSection:addButton("Search Emotes", function() runSearch(false) end)
	catSection:addButton("Load More", function() runSearch(true) end)

	-- ===== Play by ID =====
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
		task.wait(1)
		loadMine()
	end)

	ctx.modules.emotes = {
		shutdown = function()
			stopEmote()
			keepConn:Disconnect()
			charConn:Disconnect()
		end,
	}
end