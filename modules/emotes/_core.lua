return {order = 0, page = false, build = function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local HttpService = game:GetService("HttpService")
	local LocalPlayer = Players.LocalPlayer

	local E = {opts = {keepMoving = false, loopEmote = false}, favList = {}}
	ctx.emotes = E
	local activeTrack, trackDirect, stopped, lastPos = nil, false, true, 0
	local painters = {} 

	local function humanoid()
		local c = LocalPlayer.Character
		return c and c:FindFirstChildWhichIsA("Humanoid")
	end
	local function animatorOf(h) return h and h:FindFirstChildWhichIsA("Animator") end
	function E.humanoid() return humanoid() end
	function E.thumb(id) return "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=150&h=150" end

	-- ===== favorit  =====
	local FAV_DIR = (ctx.Cfg and ctx.Cfg.ConfigFolder) or "ProjectControlPanel"
	local FAV_FILE = FAV_DIR .. "/emote-favorites.json"

	if isfile and readfile then
		local ok, data = pcall(function()
			if isfile(FAV_FILE) then return HttpService:JSONDecode(readfile(FAV_FILE)) end
		end)
		if ok and type(data) == "table" then
			for _, e in ipairs(data) do
				if type(e) == "table" and tonumber(e.id) then
					table.insert(E.favList, {id = tonumber(e.id), name = tostring(e.name or e.id)})
				end
			end
		end
	end

	local function saveFavs()
		if not writefile then return end
		pcall(function()
			if makefolder and isfolder and not isfolder(FAV_DIR) then makefolder(FAV_DIR) end
			writefile(FAV_FILE, HttpService:JSONEncode(E.favList))
		end)
	end

	function E.isFav(id)
		for _, f in ipairs(E.favList) do if f.id == id then return true end end
		return false
	end

	local function setFavorite(id, name, on)
		local idx
		for i, f in ipairs(E.favList) do
			if f.id == id then idx = i; break end
		end
		if on and not idx then
			table.insert(E.favList, {id = id, name = name})
		elseif not on and idx then
			table.remove(E.favList, idx)
		end
		saveFavs()
		local list = painters[id]
		if list then
			for i = #list, 1, -1 do
				if not list[i](on) then table.remove(list, i) end
			end
		end
		if E.refreshFavorites then task.defer(E.refreshFavorites) end
	end

	function E.addEntry(grid, id, name)
		local _, paint = grid:Add(E.thumb(id), name, function() E.play(id, name) end, {
			on = E.isFav(id),
			onToggle = function(state) setFavorite(id, name, state) end,
		})
		if paint then
			painters[id] = painters[id] or {}
			table.insert(painters[id], paint)
		end
	end

	-- ===== play emote =====
	local function isAction(p)
		return p == Enum.AnimationPriority.Action or p == Enum.AnimationPriority.Action2
			or p == Enum.AnimationPriority.Action3 or p == Enum.AnimationPriority.Action4
	end

	function E.stop()
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

	function E.setLoop(v)
		if v and activeTrack then pcall(function() activeTrack.Looped = true end) end
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
			if E.opts.loopEmote then track.Looped = true end
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
								if E.opts.loopEmote then t.Looped = true end
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
					if E.opts.loopEmote then track.Looped = true end
				end)
				return track
			end
			return true
		end
		return nil
	end

	function E.play(id, name)
		E.stop()
		local track, direct = nil, false
		if E.opts.keepMoving or E.opts.loopEmote then
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

	-- Keep Moving
	local keepConn = RunService.Heartbeat:Connect(function()
		if stopped or not activeTrack then return end

		if not E.opts.keepMoving and trackDirect then
			local h = humanoid()
			if h then
				local st = h:GetState()
				if h.MoveDirection.Magnitude > 0.1 or st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
					E.stop()
					return
				end
			end
		end

		if activeTrack.IsPlaying then
			lastPos = activeTrack.TimePosition
			return
		end
		local finished = activeTrack.Length > 0 and lastPos >= activeTrack.Length - 0.2
		if finished and not E.opts.loopEmote then
			stopped, activeTrack = true, nil
		elseif E.opts.keepMoving then
			pcall(function()
				activeTrack.Priority = Enum.AnimationPriority.Action4
				if E.opts.loopEmote then activeTrack.Looped = true end
				activeTrack:Play(0.15)
			end)
		else
			stopped, activeTrack = true, nil
		end
	end)
	local charConn = LocalPlayer.CharacterAdded:Connect(function()
		activeTrack, stopped, trackDirect = nil, true, false
	end)

	ctx.modules["emotes.core"] = {
		shutdown = function()
			E.stop()
			keepConn:Disconnect()
			charConn:Disconnect()
		end,
	}
end}