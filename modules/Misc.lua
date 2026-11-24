return function(ctx)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local VirtualUser = game:GetService("VirtualUser")
	local antiAfkConnection

	local function setAntiAfk(state)
		if state then
			if antiAfkConnection then return end
			antiAfkConnection = LocalPlayer.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		elseif antiAfkConnection then
			antiAfkConnection:Disconnect()
			antiAfkConnection = nil
		end
	end

	local page = UI:addPage("Misc")
	ctx.pages.Misc = page

	local afkSection = page:addSection("Anti AFK")
	afkSection:addToggle("Anti AFK", false, function(v)
		setAntiAfk(v)
		ctx.afk.start = v and os.clock() or nil 
		ctx.updateAfkDisplay()
	end)
	ctx.afk.info = afkSection:addInfo("Active time", "--:--:--")
	afkSection:addLabel("Prevents you from being kicked for idling (about 20 minutes without input). The timer counts from when the toggle is switched on and also shows in the bar when the panel is minimized.")

	ctx.modules.misc = {
		shutdown = function()
			setAntiAfk(false)
			ctx.afk.start = nil
		end,
	}
end