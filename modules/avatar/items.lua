return {order = 40, build = function(ctx, tab)
	local UI, A = ctx.UI, ctx.avatar
	local Players = game:GetService("Players")
	local Marketplace = game:GetService("MarketplaceService")
	local AssetService = game:GetService("AssetService")

	-- AssetTypeId -> tipe aksesori (aksesori & layered clothing)
	local accessoryTypes = {
		[8] = "Hat", [41] = "Hair", [42] = "Face", [43] = "Neck", [44] = "Shoulder", [45] = "Front", [46] = "Back", [47] = "Waist",
		[64] = "TShirt", [65] = "Shirt", [66] = "Pants", [67] = "Jacket", [68] = "Sweater", [69] = "Shorts",
		[70] = "LeftShoe", [71] = "RightShoe", [72] = "DressSkirt", [76] = "Eyebrow", [77] = "Eyelash",
	}
	-- AssetTypeId -> field di HumanoidDescription (badan & pakaian classic)
	local descFields = {
		[2] = "GraphicTShirt", [11] = "Shirt", [12] = "Pants", [18] = "Face",
		[17] = "Head", [79] = "Head", [27] = "Torso", [28] = "RightArm", [29] = "LeftArm", [30] = "LeftLeg", [31] = "RightLeg",
	}
	local outfitFields = {
		"Head", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg", "Face", "Shirt", "Pants", "GraphicTShirt",
		"HeightScale", "WidthScale", "DepthScale", "HeadScale", "ProportionScale", "BodyTypeScale",
	}

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

	local function addBundle(id)
		local ok, details = pcall(function() return AssetService:GetBundleDetails(id) end)
		if not ok or type(details) ~= "table" then return false end
		for _, item in ipairs(details.Items or {}) do
			if item.Type == "UserOutfit" then
				local okO, od = pcall(function() return Players:GetHumanoidDescriptionFromOutfitId(item.Id) end)
				if okO and od then
					for _, f in ipairs(outfitFields) do
						pcall(function() A.desc[f] = od[f] end)
					end
				end
			elseif item.Type == "Asset" then
				local okI, info = pcall(function() return Marketplace:GetProductInfo(item.Id, Enum.InfoType.Asset) end)
				if okI and type(info) == "table" then addToDescription(item.Id, info.AssetTypeId) end
			end
		end
		return true, details.Name
	end

	local function rebuild(name)
		local ok, why = A.build(A.desc)
		if ok then
			UI:notify("Equipped: " .. tostring(name):sub(1, 30), "success")
		else
			UI:notify("Equip failed: " .. tostring(why), "error")
		end
	end

	local function parseId(text)
		local id = tonumber((tostring(text):gsub("%D", "")))
		if not id then UI:notify("Invalid ID", "error") end
		return id
	end

	local function equipItem(text)
		local id = parseId(text)
		if not id then return end
		if not A.desc then
			UI:notify("Avatar not loaded yet", "error")
			return
		end
		local okInfo, info = pcall(function() return Marketplace:GetProductInfo(id, Enum.InfoType.Asset) end)
		if okInfo and type(info) == "table" and info.AssetTypeId then
			local added, why = addToDescription(id, info.AssetTypeId)
			if not added then
				UI:notify("Cannot add item: " .. tostring(why), "error")
				return
			end
			rebuild(info.Name or id)
			return
		end
		local okB, name = addBundle(id) -- bukan item biasa: coba sebagai bundle
		if okB then
			rebuild(name or id)
		else
			UI:notify("Item not found", "error")
		end
	end

	local function equipBundle(text)
		local id = parseId(text)
		if not id then return end
		if not A.desc then
			UI:notify("Avatar not loaded yet", "error")
			return
		end
		local okB, name = addBundle(id)
		if okB then
			rebuild(name or id)
		else
			UI:notify("Bundle not found", "error")
		end
	end

	local section = tab:addSection("Equip Item")
	local box = section:addTextBox("Item ID", "Enter item ID", function(text, enter)
		if enter then equipItem(text) end -- Enter = langsung pasang
	end)
	section:addButton("Equip Item", function() equipItem(box:Get()) end)
	section:addButton("Equip Bundle", function() equipBundle(box:Get()) end)
	section:addButton("Remove Accessories", function()
		if not A.desc then return end
		pcall(function() A.desc:SetAccessories({}, true) end)
		local ok, why = A.build(A.desc)
		UI:notify(ok and "Accessories removed" or ("Failed: " .. tostring(why)), ok and "success" or "error")
	end)
	section:addLabel("Works for accessories, layered clothing, head, torso, arms, legs, face, shirts, pants and t-shirts. Use the ID from the catalog page URL; for a bundle, use Equip Bundle. The avatar is rebuilt in place, without respawning.")
end}