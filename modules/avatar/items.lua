return {order = 40, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local Marketplace = game:GetService("MarketplaceService")

	-- AssetTypeId -> tipe aksesori / field di HumanoidDescription
	local accessoryTypes = {
		[8] = "Hat", [41] = "Hair", [42] = "Face", [43] = "Neck", [44] = "Shoulder", [45] = "Front", [46] = "Back", [47] = "Waist",
		[64] = "TShirt", [65] = "Shirt", [66] = "Pants", [67] = "Jacket", [68] = "Sweater", [69] = "Shorts",
		[70] = "LeftShoe", [71] = "RightShoe", [72] = "DressSkirt", [76] = "Eyebrow", [77] = "Eyelash",
	}
	local descFields = {[2] = "GraphicTShirt", [11] = "Shirt", [12] = "Pants", [18] = "Face"}

	local function addToDescription(id, typeId)
		local d = A.desc
		if not d then return false, "avatar not loaded yet" end
		if descFields[typeId] then
			d[descFields[typeId]] = id
			return true
		end
		local okType, aType = pcall(function() return Enum.AccessoryType[accessoryTypes[typeId]] end)
		if not (accessoryTypes[typeId] and okType and aType) then
			return false, "unsupported item type (" .. tostring(typeId) .. ")"
		end
		local ok, err = pcall(function()
			local list = d:GetAccessories(true)
			table.insert(list, {AssetId = id, AccessoryType = aType, Order = #list + 1, IsLayered = typeId >= 64})
			d:SetAccessories(list, true)
		end)
		if not ok then return false, A.short(err) end
		return true
	end

	-- cadangan pratinjau kalau ApplyDescription ditolak: pasang item langsung ke karakter
	local function localEquip(id)
		local c, h = A.character(), A.humanoid()
		if not (c and h) then return false end
		local ok, objs = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
		local obj = ok and objs and objs[1]
		if not obj then return false end
		if obj:IsA("Accessory") then
			h:AddAccessory(obj)
		elseif obj:IsA("Shirt") then
			local s = c:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", c)
			s.ShirtTemplate = obj.ShirtTemplate
		elseif obj:IsA("Pants") then
			local p = c:FindFirstChildOfClass("Pants") or Instance.new("Pants", c)
			p.PantsTemplate = obj.PantsTemplate
		elseif obj:IsA("ShirtGraphic") then
			local g = c:FindFirstChildOfClass("ShirtGraphic") or Instance.new("ShirtGraphic", c)
			g.Graphic = obj.Graphic
		else
			return false
		end
		return true
	end

	local function equip(text)
		local id = tonumber((tostring(text):gsub("%D", "")))
		if not id then
			UI:notify("Invalid item ID", "error")
			return
		end
		local okInfo, info = pcall(function() return Marketplace:GetProductInfo(id, Enum.InfoType.Asset) end)
		if not okInfo or type(info) ~= "table" then
			UI:notify("Item not found", "error")
			return
		end
		local added, why = addToDescription(id, info.AssetTypeId)
		if not added then
			UI:notify("Cannot add item: " .. tostring(why), "error")
			return
		end
		local ok = A.preview()
		if not ok then ok = localEquip(id) end
		local name = tostring(info.Name or id):sub(1, 30)
		if ok then
			UI:notify("Equipped: " .. name .. " (only you see it until you save)", "success")
		else
			UI:notify("Preview failed, but " .. name .. " is queued for saving", "info")
		end
	end

	local section = tab:addSection("Equip Item")
	local box = section:addTextBox("Item ID", "Enter item ID", function(text, enter)
		if enter then equip(text) end -- Enter = langsung pasang
	end)
	section:addButton("Equip Item", function() equip(box:Get()) end)
	section:addButton("Remove Accessories", function()
		if A.desc then pcall(function() A.desc:SetAccessories({}, true) end) end
		local ok = A.preview()
		if not ok then
			local h = A.humanoid()
			if h then pcall(function() for _, a in ipairs(h:GetAccessories()) do a:Destroy() end end) end
		end
		UI:notify("Accessories removed", "success")
	end)
	section:addLabel("The item type is detected automatically from the catalog ID. Use the item ID from the catalog page URL.")
end}