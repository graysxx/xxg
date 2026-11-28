return {order = 46, build = function(ctx, tab)
	local UI = ctx.UI
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local FAR = Vector3.new(-25.95, 84, 3537.55)
	local enabled, seat, saved = false, nil, nil

	local function stop()
		if seat then seat:Destroy(); seat = nil end
		local c = LocalPlayer.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if root and saved then root.CFrame = saved end
		saved = nil
	end

	local function start()
		local c = LocalPlayer.Character
		local root = c and c:FindFirstChild("HumanoidRootPart")
		local torso = c and (c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
		if not (root and torso) then
			UI:notify("No character", "error")
			return false
		end
		saved = root.CFrame
		c:PivotTo(CFrame.new(FAR))
		task.wait(0.15)
		seat = Instance.new("Seat")
		seat.Name = "XXG_InvisSeat"
		seat.Anchored = false
		seat.CanCollide = false
		seat.Transparency = 1
		seat.Position = FAR
		seat.Parent = workspace
		local weld = Instance.new("Weld")
		weld.Part0, weld.Part1 = seat, torso
		weld.Parent = seat
		task.wait()
		seat.CFrame = saved
		return true
	end

	local section = tab:addSection("Invisible")
	local toggle
	toggle = section:addToggle("Enabled", false, function(v)
		if v then
			if not start() then
				toggle:Set(false)
				return
			end
		else
			stop()
		end
		enabled = v
	end)
	section:addLabel("Experimental: hides your character from other players. Turn it off before respawning. It may not work in every game.")

	local charConn = LocalPlayer.CharacterAdded:Connect(function()
		if enabled then
			enabled = false
			if seat then seat:Destroy(); seat = nil end
			saved = nil
			toggle:Set(false)
		end
	end)

	ctx.modules["player.invisible"] = {
		shutdown = function()
			if enabled then stop() end
			enabled = false
			charConn:Disconnect()
		end,
	}
end}