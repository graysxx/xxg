return {order = 40, build = function(ctx, tab)
	local Cfg = ctx.Cfg
	if Cfg.News and #Cfg.News > 0 then
		tab:addNewsCard(Cfg.NewsTitle or "What's New", Cfg.News)
	end
end}