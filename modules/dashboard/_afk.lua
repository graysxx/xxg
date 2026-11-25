return {order = 0, page = false, build = function(ctx)
	local UI, Theme = ctx.UI, ctx.Theme
	ctx.afk = {start = nil, info = nil}

	local function fmtHMS(s)
		s = math.floor(s)
		return string.format("%02d:%02d:%02d", math.floor(s / 3600), math.floor(s % 3600 / 60), s % 60)
	end

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
end}