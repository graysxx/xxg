return {order = 10, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local Players = game:GetService("Players")
	local busy = false

	local function copyFrom(text)
		local name = tostring(text):gsub("[^%w_]", "")
		if name == "" then
			UI:notify("Enter a username", "error")
			return
		end
		if busy then return end
		busy = true
		local okId, userId = pcall(function() return Players:GetUserIdFromNameAsync(name) end)
		if not okId then
			busy = false
			UI:notify("Player not found", "error")
			return
		end
		local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
		if not okDesc then
			busy = false
			UI:notify("Failed to load avatar", "error")
			return
		end
		local ok, err = A.apply(desc)
		busy = false
		if ok then
			UI:notify("Avatar applied", "success")
		else
			UI:notify("Failed to apply avatar", "error")
			warn("[ControlPanel] avatar: " .. tostring(err))
		end
	end

	local section = tab:addSection("Copy Avatar")
	local box = section:addTextBox("Username", "Enter username", function(text, enter)
		if enter then copyFrom(text) end -- Enter = langsung terapkan
	end)
	section:addButton("Apply Avatar", function() copyFrom(box:Get()) end)
	section:addLabel("Applies another player's avatar to your character. Only you can see the change.")
end}