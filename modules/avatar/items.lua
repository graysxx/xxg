return {order = 40, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local kind = "Accessory"

	local section = tab:addSection("Equip Item")
	local drop = section:addDropdown("Item Type", {"Accessory", "Shirt", "Pants", "T-Shirt", "Face"}, function(name)
		kind = name
	end)
	drop:Set("Accessory")

	local function equip(text)
		local id = tonumber((tostring(text):gsub("%D", "")))
		if not id then
			UI:notify("Invalid item ID", "error")
			return
		end
		local c, h = A.character(), A.humanoid()
		if not (c and h) then return end
		local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		local obj = ok and objs and objs[1]
		if not obj then
			UI:notify("Failed to load item", "error")
			return
		end

		local done = false
		if kind == "Accessory" and obj:IsA("Accessory") then
			h:AddAccessory(obj)
			done = true
		elseif kind == "Shirt" and obj:IsA("Shirt") then
			local s = c:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", c)
			s.ShirtTemplate = obj.ShirtTemplate
			done = true
		elseif kind == "Pants" and obj:IsA("Pants") then
			local p = c:FindFirstChildOfClass("Pants") or Instance.new("Pants", c)
			p.PantsTemplate = obj.PantsTemplate
			done = true
		elseif kind == "T-Shirt" and obj:IsA("ShirtGraphic") then
			local g = c:FindFirstChildOfClass("ShirtGraphic") or Instance.new("ShirtGraphic", c)
			g.Graphic = obj.Graphic
			done = true
		elseif kind == "Face" and obj:IsA("Decal") then
			local head = c:FindFirstChild("Head")
			local face = head and head:FindFirstChildOfClass("Decal")
			if face then
				face.Texture = obj.Texture
				done = true
			end
		end
		UI:notify(done and "Item equipped" or "Item type does not match", done and "success" or "error")
	end

	local box = section:addTextBox("Item ID", "Enter item ID", function(text, enter)
		if enter then equip(text) end -- Enter = langsung pasang
	end)
	section:addButton("Equip Item", function() equip(box:Get()) end)
	section:addButton("Remove Accessories", function()
		local h = A.humanoid()
		if not h then return end
		pcall(function()
			for _, a in ipairs(h:GetAccessories()) do a:Destroy() end
		end)
		UI:notify("Accessories removed", "success")
	end)
end}