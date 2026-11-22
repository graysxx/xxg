return function(ctx)
	local UI, Theme, Cfg, L = ctx.UI, ctx.Theme, ctx.Cfg, ctx.L
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer

	local page = UI:addPage("Dashboard")
	ctx.pages.Dashboard = page
	UI:SelectPage(page) -- langsung tampilkan Dashboard saat GUI muncul

	local heading = page:addHeading("Overview", "Dashboard", L("welcome", LocalPlayer.DisplayName))
	UI:onLanguage(function() heading.Subtitle.Text = L("welcome", LocalPlayer.DisplayName) end)

	local stats = page:addStats({
		{Key = "ping",    Icon = "signal", Title = "NETWORK",     Color = Theme.Green,  Value = "-- ms",   Status = "• Connecting", StatusColor = Theme.Green},
		{Key = "fps",     Icon = "chart",  Title = "PERFORMANCE", Color = Theme.Accent, Value = "-- FPS",  Status = "• Measuring",  StatusColor = Theme.Accent},
		{Key = "server",  Icon = "users",  Title = "SERVER",      Color = Theme.Orange, Value = "-- / --", Status = "Active Players"},
		{Key = "session", Icon = "clock",  Title = "SESSION",     Color = Theme.Blue,   Value = "00:00",   Status = "Session duration"},
	})

	page:addAccountCard({
		UserId = LocalPlayer.UserId,
		Name = LocalPlayer.Name,
		DisplayName = LocalPlayer.DisplayName,
		Status = "Active",
	})

	-- profil yang tampil di bar saat panel di-minimize
	UI:setMiniProfile({UserId = LocalPlayer.UserId, Name = LocalPlayer.Name, DisplayName = LocalPlayer.DisplayName})

	if Cfg.News and #Cfg.News > 0 then
		page:addNewsCard(Cfg.NewsTitle or "What's New", Cfg.News)
	end

	-- kartu versi (cek "terbaru / outdated" kalau Cfg.VersionURL diisi)
	local versionCard = page:addVersionCard({
		Version = Cfg.Version,
		Updated = Cfg.Updated,
		Status = "Not checked",
	})
	if Cfg.VersionURL and Cfg.VersionURL ~= "" then
		task.spawn(function()
			local ok, latest = pcall(function() return game:HttpGet(Cfg.VersionURL) end)
			if not ok then
				versionCard:SetStatus("Check failed", Theme.Orange)
				return
			end
			latest = tostring(latest):gsub("%s+", "")
			if latest == Cfg.Version then
				versionCard:SetStatus("Up to date", Theme.Green)
			else
				versionCard:SetStatus("Outdated (" .. latest .. ")", Theme.Orange)
			end
		end)
	end

	-- timer Anti AFK (diisi oleh Modules/Misc.lua)
	ctx.afk = {start = nil, info = nil}

	local function fmtHMS(s)
		s = math.floor(s)
		return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60)
	end

	-- tampilkan timer Anti AFK di Misc dan bar minimize
	function ctx.updateAfkDisplay()
		local afk = ctx.afk
		if afk.start then
			local t = fmtHMS(os.clock() - afk.start)
			UI:setMini("afk", t, Theme.Green)
			if afk.info then afk.info:Set(t, Theme.Green) end
		else
			UI:setMini("afk", nil)
			if afk.info then afk.info:Set("--:--:--", Theme.Muted) end
		end
	end

	-- update statistik Dashboard
	local startTime = os.clock()
	local frames, fpsTime, slowTime = 0, 0, 0
	local function fmtTime(s)
		s = math.floor(s)
		local h, m, sec = math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60
		if h > 0 then return string.format("%d:%02d:%02d", h, m, sec) end
		return string.format("%02d:%02d", m, sec)
	end
	UI:connect(RunService.Heartbeat, function(dt)
		frames = frames + 1
		fpsTime = fpsTime + dt
		slowTime = slowTime + dt
		if fpsTime >= 0.5 then
			local fps = math.floor(frames / fpsTime + 0.5)
			frames, fpsTime = 0, 0
			if fps >= 50 then
				stats.fps:Set(fps .. " FPS", "• Stable", Theme.Accent)
				UI:setMini("fps", fps .. " FPS", Theme.Accent)
			else
				stats.fps:Set(fps .. " FPS", "• Low", Theme.Orange)
				UI:setMini("fps", fps .. " FPS", Theme.Orange)
			end
		end
		if slowTime >= 1 then
			slowTime = 0
			local okPing, ping = pcall(function()
				return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if okPing and ping and ping > 0 then
				ping = math.floor(ping)
				if ping < 150 then
					stats.ping:Set(ping .. " ms", "• Connected", Theme.Green)
					UI:setMini("ping", ping .. " ms", Theme.Green)
				else
					stats.ping:Set(ping .. " ms", "• High latency", Theme.Orange)
					UI:setMini("ping", ping .. " ms", Theme.Orange)
				end
			end
			stats.server:Set(#Players:GetPlayers() .. " / " .. Players.MaxPlayers)
			stats.session:Set(fmtTime(os.clock() - startTime))
			ctx.updateAfkDisplay()
		end
	end)
end