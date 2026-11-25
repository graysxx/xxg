return {order = 50, build = function(ctx, tab)
	local Cfg, Theme = ctx.Cfg, ctx.Theme
	local card = tab:addVersionCard({Version = Cfg.Version, Updated = Cfg.Updated, Status = "Not checked"})
	if Cfg.VersionURL and Cfg.VersionURL ~= "" then
		task.spawn(function()
			local ok, latest = pcall(function() return game:HttpGet(Cfg.VersionURL) end)
			if not ok then
				card:SetStatus("Check failed", Theme.Orange)
				return
			end
			latest = tostring(latest):gsub("%s+", "")
			if latest == Cfg.Version then
				card:SetStatus("Up to date", Theme.Green)
			else
				card:SetStatus("Outdated (" .. latest .. ")", Theme.Orange)
			end
		end)
	end
end}