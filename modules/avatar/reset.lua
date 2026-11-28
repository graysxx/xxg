return {order = 90, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local section = tab:addSection("Reset Avatar")
	section:addButton("Reset Avatar", function()
		local ok, err = A.reset()
		if ok then
			UI:notify("Avatar reset", "success")
		else
			UI:notify("Failed to reset avatar", "error")
			warn("[ControlPanel] avatar: " .. tostring(err))
		end
	end)
	section:addLabel("Restores your original avatar. Use it after copying another avatar or equipping items.")
end}