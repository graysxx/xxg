return {order = 80, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local section = tab:addSection("Share With Everyone")

	section:addButton("Save to My Roblox Account", function()
		UI:notify("Confirm the Roblox dialog to save", "info")
		local ok, why = A.save()
		if ok then
			UI:notify("Saved. Respawn to show it to everyone", "success")
		else
			UI:notify("Save failed: " .. tostring(why), "error")
		end
	end)

	section:addButton("Reset Avatar", function()
		if not A.original then
			UI:notify("Original avatar not loaded yet", "error")
			return
		end
		A.desc = A.original:Clone()
		local ok, err = A.preview()
		if ok then
			UI:notify("Avatar reset (preview only)", "success")
		else
			UI:notify("Reset preview failed: " .. tostring(err), "error")
		end
	end)

	section:addLabel("Other players only see what is saved on your account. Save opens Roblox's own confirmation dialog and replaces your real avatar (only items you own are kept). Respawn afterwards. Games with custom characters ignore it. To go back: Reset Avatar, then save again.")
end}