return {order = 44, build = function(ctx, tab)
	local UI, P = ctx.UI, ctx.player
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local enabled, showPlatform = false, false
	local platform, platformY

	local function destroyPlatform()
		if platform then platform:Destroy(); platform = nil end
		platformY = nil
	end

	local section = tab:addSection("Airwalk")
	section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then destroyPlatform() end
	end)
	section:addToggle("Show Platform", false, function(v)
		showPlatform = v
		if platform then platform.Transparency = v and 0.6 or 1 end
	end)
	section:addLabel("Walk on thin air: an invisible platform follows you at the height where you turned it on. Hold E to raise it and Q to lower it. Only you see the platform; other players see you floating.")

	local function feetOffset(h, root)
		if h.RigType == Enum.HumanoidRigType.R6 then return 3 end
		return h.HipHeight + root.Size.Y / 2
	end

	local conn = RunService.Stepped:Connect(function(_, dt)
		if not enabled then return end
		local h = P.humanoid()
		local root = h and h.RootPart
		if not root or h.Health <= 0 then return end

		if not platform then
			platform = Instance.new("Part")
			platform.Name = "XXG_Airwalk"
			platform.Size = Vector3.new(8, 1, 8)
			platform.Anchored = true
			platform.CanCollide = true
			platform.Transparency = showPlatform and 0.6 or 1
			platform.Parent = workspace
		end
		if not platformY then platformY = root.Position.Y - feetOffset(h, root) end

		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then platformY = platformY + 14 * dt end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then platformY = platformY - 14 * dt end
		end
		platform.CFrame = CFrame.new(root.Position.X, platformY - platform.Size.Y / 2, root.Position.Z)
	end)

	-- setelah respawn, ketinggian platform dihitung ulang dari posisi baru
	local charConn = LocalPlayer.CharacterAdded:Connect(function() platformY = nil end)

	ctx.modules["player.airwalk"] = {
		shutdown = function()
			enabled = false
			destroyPlatform()
			conn:Disconnect()
			charConn:Disconnect()
		end,
	}
end}