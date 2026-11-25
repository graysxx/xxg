return {order = 20, build = function(ctx, tab)
	local UI = ctx.UI
	local RunService = game:GetService("RunService")
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local enabled = false
	local touched = {} -- [BasePart] = true

	local function restore()
		for part in pairs(touched) do
			if part.Parent then part.CanCollide = true end
		end
		table.clear(touched)
	end

	local section = tab:addSection("Noclip")
	local toggle = section:addToggle("Enabled", false, function(v)
		enabled = v
		if not v then restore() end
	end)
	section:addLabel("Walk through walls and objects. You still stand on the ground.")

	table.insert(ctx.keybinds, {
		title = "Toggle Noclip",
		default = Enum.KeyCode.N,
		callback = function() toggle:Set(not toggle:Get()) end,
	})

	local conn = RunService.Stepped:Connect(function()
		if not enabled then return end
		local c = LocalPlayer.Character
		if not c then return end
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") and d.CanCollide then
				touched[d] = true
				d.CanCollide = false
			end
		end
	end)

	ctx.modules["misc.noclip"] = {
		shutdown = function()
			enabled = false
			restore()
			conn:Disconnect()
		end,
	}
end}