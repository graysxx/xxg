return {order = 1, page = false, build = function(ctx)
	local UI = ctx.UI
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer

	local T = {target = nil, lastKnown = nil, listNames = {}, byLabel = {}, onClear = {}}
	ctx.target = T
	local noticeAt = 0

	function T.notice(text)
		if os.clock() - noticeAt > 3 then
			noticeAt = os.clock()
			UI:notify(text, "error")
		end
	end

	function T.myParts()
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildWhichIsA("Humanoid")
		return h, h and h.RootPart
	end

	function T.root()
		local c = T.target and T.target.Character
		if not c then return nil end
		local h = c:FindFirstChildWhichIsA("Humanoid")
		return (h and h.RootPart) or c:FindFirstChild("HumanoidRootPart")
			or c:FindFirstChild("Head") or c:FindFirstChildWhichIsA("BasePart")
	end

	function T.rebuild(exclude)
		table.clear(T.listNames)
		table.clear(T.byLabel)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p ~= exclude then
				local label = p.DisplayName .. " (@" .. p.Name .. ")"
				table.insert(T.listNames, label)
				T.byLabel[label] = p
			end
		end
		table.sort(T.listNames, function(a, b) return a:lower() < b:lower() end)
	end
	T.rebuild()

	function T.setTarget(p) 
		T.target, T.lastKnown = p, nil
		if T.targetInfo then T.targetInfo:Set(p and p.DisplayName or "None") end
		if not p then
			if T.playerDrop then T.playerDrop:Set("") end
			for _, fn in ipairs(T.onClear) do pcall(fn) end
		end
	end

	local added = Players.PlayerAdded:Connect(function() T.rebuild() end)
	local removing = Players.PlayerRemoving:Connect(function(p)
		if p == T.target then
			T.setTarget(nil)
			UI:notify("Target left the game", "info")
		end
		T.rebuild(p)
	end)
	local track = RunService.Heartbeat:Connect(function()
		if not T.target then return end
		local r = T.root()
		if r then T.lastKnown = r.CFrame end
	end)

	ctx.modules["player.target"] = {
		shutdown = function()
			added:Disconnect(); removing:Disconnect(); track:Disconnect()
		end,
	}
end}