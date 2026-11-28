return {order = 10, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local Players = game:GetService("Players")
	local busy = false

	-- cadangan kalau ApplyDescription ditolak game: salin pakaian & aksesori langsung ke karakter
	local function previewByAppearance(userId)
		local ok, model = pcall(function() return Players:GetCharacterAppearanceAsync(userId) end)
		if not ok or not model then return false, "appearance load failed" end
		local c, h = A.character(), A.humanoid()
		if not (c and h) then return false, "no character" end
		for _, d in ipairs(c:GetChildren()) do
			if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") then
				d:Destroy()
			end
		end
		for _, d in ipairs(model:GetChildren()) do
			if d:IsA("Accessory") then
				h:AddAccessory(d)
			elseif d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("BodyColors") then
				d.Parent = c
			end
		end
		return true
	end

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
		local ok, err = A.preview()
		if not ok then
			ok, err = previewByAppearance(userId) -- cara kedua
		end
		busy = false
		if ok then
			UI:notify("Avatar applied (only you see it until you save)", "success")
		else
			UI:notify("Preview failed: " .. tostring(err) .. " (you can still save it)", "error")
		end
	end

	local section = tab:addSection("Copy Avatar")
	local box = section:addTextBox("Username", "Enter username", function(text, enter)
		if enter then copyFrom(text) end -- Enter = langsung terapkan
	end)
	section:addButton("Apply Avatar", function() copyFrom(box:Get()) end)
	section:addLabel("Applies another player's avatar to your character. Only you can see it until you save it to your account (see Share With Everyone).")
end}