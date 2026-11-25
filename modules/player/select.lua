return {order = 50, build = function(ctx, tab)
	local UI, T = ctx.UI, ctx.target
	local section = tab:addSection("Target Player")

	T.playerDrop = section:addDropdown("Select Player", T.listNames, function(label)
		local p = T.byLabel[label]
		if p then T.setTarget(p) end
	end)
	T.targetInfo = section:addInfo("Target", UI:tr("None"))

	section:addButton("Clear Target", function()
		T.setTarget(nil)
		UI:notify("Target cleared", "success")
	end)

	section:addButton("Teleport to Target", function()
		if not T.target then
			UI:notify("Select a player first", "error")
			return
		end
		local h, root = T.myParts()
		if not (h and root) then
			UI:notify("Target not available", "error")
			return
		end
		if h.SeatPart then
			UI:notify("Leave the vehicle first", "error")
			return
		end
		local tRoot = T.root()
		if tRoot then
			root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4) -- 4 studs behind
			UI:notify("Teleported to target", "success")
		elseif T.lastKnown then
			root.CFrame = T.lastKnown * CFrame.new(0, 0, 4)
			UI:notify("Target not loaded, moved to last known position", "info")
		else
			UI:notify("Target is too far (not loaded)", "error")
		end
	end)
end}