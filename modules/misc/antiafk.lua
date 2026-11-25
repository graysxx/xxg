return {order = 10, build = function(ctx, tab)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local VirtualUser = game:GetService("VirtualUser")
	local conn

	local function setAntiAfk(state)
		if state then
			if conn then return end
			conn = LocalPlayer.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		elseif conn then
			conn:Disconnect()
			conn = nil
		end
	end

	local section = tab:addSection("Anti AFK")
	section:addToggle("Anti AFK", false, function(v)
		setAntiAfk(v)
		if ctx.afk then ctx.afk.start = v and os.clock() or nil end
		if ctx.updateAfkDisplay then ctx.updateAfkDisplay() end
	end)
	if ctx.afk then ctx.afk.info = section:addInfo("Active time", "--:--:--") end
	section:addLabel("Prevents you from being kicked for idling (about 20 minutes without input). The timer counts from when the toggle is switched on and also shows in the bar when the panel is minimized.")

	ctx.modules["misc.antiafk"] = {
		shutdown = function()
			setAntiAfk(false)
			if ctx.afk then ctx.afk.start = nil end
		end,
	}
end}