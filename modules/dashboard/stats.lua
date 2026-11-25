return {order = 20, build = function(ctx, tab)
	local UI, Theme = ctx.UI, ctx.Theme
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	local stats = tab:addStats({
		{Key = "ping",    Icon = "signal", Title = "NETWORK",     Color = Theme.Green,  Value = "-- ms",   Status = "• Connecting", StatusColor = Theme.Green},
		{Key = "fps",     Icon = "chart",  Title = "PERFORMANCE", Color = Theme.Accent, Value = "-- FPS",  Status = "• Measuring",  StatusColor = Theme.Accent},
		{Key = "server",  Icon = "users",  Title = "SERVER",      Color = Theme.Orange, Value = "-- / --", Status = "Active Players"},
		{Key = "session", Icon = "clock",  Title = "SESSION",     Color = Theme.Blue,   Value = "00:00",   Status = "Session duration"},
	})

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
			if ctx.updateAfkDisplay then ctx.updateAfkDisplay() end
		end
	end)
end}