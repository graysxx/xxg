return {order = 90, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local section = tab:addSection("Reset Avatar")
	section:addButton("Reset Avatar", function()
		local ok, why = A.reset()
		if ok then
			UI:notify("Avatar reset", "success")
		else
			UI:notify("Reset failed: " .. tostring(why), "error")
		end
	end)
	section:addLabel("Restores your original avatar in place, without respawning.")
end}