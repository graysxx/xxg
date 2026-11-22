return function(ctx)
	local UI, Cfg = ctx.UI, ctx.Cfg

	repeat task.wait(0) until game:IsLoaded() and game.PlaceId > 0
	local entry = Cfg.Games and Cfg.Games[game.PlaceId]
	if not entry then return end

	local features = {
		DrivingEmpire = function(page)

			task.spawn(function()
				local ok, err = pcall(function()
					local section = page:addSection("Vehicle Dealership")
					local list = {}
					for _, v in pairs(workspace:WaitForChild("Game"):WaitForChild("Dealerships"):WaitForChild("Dealerships"):GetChildren()) do
						table.insert(list, v.Name)
					end
					section:addDropdown("Dealership", list, function(name)
						game:GetService("ReplicatedStorage").Remotes.Location:FireServer("Enter", name)
					end)
				end)
				if not ok then warn("[ControlPanel] DrivingEmpire: " .. tostring(err)) end
			end)
		end,
	}

	local page = UI:addPage(entry.Page)
	local build = entry.Feature and features[entry.Feature]
	if build then
		build(page)
	else
		page:addSection("Info"):addLabel("No game-specific features yet.")
	end
end