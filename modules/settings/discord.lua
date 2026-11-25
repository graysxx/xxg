return {order = 40, build = function(ctx, tab)
	local UI, Cfg = ctx.UI, ctx.Cfg
	if not (Cfg.Discord and Cfg.Discord.Code) then return end
	local code = Cfg.Discord.Code
	local section = tab:addSection("Discord")

	section:addButton(syn and "Join the Discord server" or "Copy Discord Link", function()
		if syn then
			local http = game:GetService("HttpService")
			syn.request({
				Url = "http://127.0.0.1:6463/rpc?v=1",
				Method = "POST",
				Headers = {["Content-Type"] = "application/json", ["Origin"] = "https://discord.com"},
				Body = http:JSONEncode({cmd = "INVITE_BROWSER", args = {code = code}, nonce = http:GenerateGUID(false)}),
			})
			UI:notify("Discord invite sent", "success")
			return
		end
		local okCopy = pcall(setclipboard, "https://www.discord.com/invite/" .. code)
		if okCopy then
			UI:notify("Discord link copied", "success")
		else
			UI:notify("Failed to copy Discord link", "error")
		end
	end)
end}