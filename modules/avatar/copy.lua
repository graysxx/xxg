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
			UI:notify("Player not found: " .. A.short(userId), "error")
			return
		end
		local okDesc, desc = pcall(function() return Players:GetHumanoidDescriptionFromUserId(userId) end)
		if not okDesc or not desc then
			busy = false
			UI:notify("Failed to load avatar: " .. A.short(desc), "error")
			return
		end

		A.desc = desc
		local ok, note = A.build(desc, userId)
		busy = false
		if ok then
			UI:notify(note or "Avatar applied (only you see it until you save)", note and "info" or "success")
		else
			UI:notify("Apply failed: " .. tostring(note), "error")
		end
	end

	local section = tab:addSection("Copy Avatar")
	local box = section:addTextBox("Username", "Enter username", function(text, enter)
		if enter then copyFrom(text) end -- Enter = langsung terapkan
	end)
	section:addButton("Apply Avatar", function() copyFrom(box:Get()) end)
	section:addLabel("Applies another player's full avatar (body, head, face, hair, accessories, layered clothing, clothes) to your character. Only you can see it until you save it to your account.")
end}