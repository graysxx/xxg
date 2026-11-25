return {order = 60, build = function(ctx, tab)
	local UI, Cfg = ctx.UI, ctx.Cfg
	local HttpService = game:GetService("HttpService")
	local ROOT_DIR = Cfg.ConfigFolder or "ProjectControlPanel"
	local CONFIG_DIR = ROOT_DIR .. "/configs"
	local fsOk = (writefile and readfile and isfolder and makefolder and listfiles and delfile) and true or false
	local configNames = {}
	local selectedDelete

	local function cfgPath(name) return CONFIG_DIR .. "/" .. name .. ".json" end

	local function letterName(n) -- 1 -> A, 26 -> Z, 27 -> AA
		local s = ""
		while n > 0 do
			local r = (n - 1) % 26
			s = string.char(65 + r) .. s
			n = (n - r - 1) // 26
		end
		return s
	end
	local function autoName()
		local i = 1
		while table.find(configNames, "Config " .. letterName(i)) do i += 1 end
		return "Config " .. letterName(i)
	end

	local function refreshConfigs()
		table.clear(configNames)
		if not fsOk then return end
		pcall(function()
			if not isfolder(ROOT_DIR) then makefolder(ROOT_DIR) end
			if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
			for _, path in ipairs(listfiles(CONFIG_DIR)) do
				local n = path:match("([^/\\]+)%.json$")
				if n then table.insert(configNames, n) end
			end
			table.sort(configNames, function(a, b) return a:lower() < b:lower() end)
		end)
	end

	-- store all module config
	local function collectConfig()
		local data = {}
		for name, m in pairs(ctx.modules) do
			if m.collect then data[name] = m.collect() end
		end
		return data
	end

	local function applyConfig(d)
		for name, m in pairs(ctx.modules) do
			if m.apply then
				-- old config 
				local part = d[name] or d[name:match("^[^.]+") or name]
				if type(part) == "table" then pcall(m.apply, part) end
			end
		end
	end

	refreshConfigs()

	local section = tab:addSection("Config")
	local nameBox = section:addTextBox("Config Name", "Enter Config Name")
	local loadDrop, delDrop

	section:addButton("Save Config", function()
		if not fsOk then
			UI:notify("Executor does not support file saving", "error")
			return
		end
		local name = nameBox:Get():gsub("[^%w _%-]", ""):gsub("^%s+", ""):gsub("%s+$", "")
		name = name:sub(1, 30)
		if name == "" then name = autoName() end
		local existed = table.find(configNames, name) ~= nil
		local ok = pcall(function()
			if not isfolder(ROOT_DIR) then makefolder(ROOT_DIR) end
			if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
			writefile(cfgPath(name), HttpService:JSONEncode(collectConfig()))
		end)
		if ok then
			refreshConfigs()
			nameBox:Set("")
			if loadDrop then loadDrop:Refresh() end
			if delDrop then delDrop:Refresh() end
			UI:notify(existed and ctx.dyn("updated", name) or ctx.dyn("saved", name), "success")
		else
			UI:notify("Failed to save config", "error")
		end
	end)

	loadDrop = section:addDropdown("Load Config", configNames, function(name)
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgPath(name))) end)
		if ok and type(data) == "table" then
			applyConfig(data)
			UI:notify(ctx.dyn("loaded", name), "success")
		else
			UI:notify("Failed to load config", "error")
		end
	end)

	delDrop = section:addDropdown("Select Config to Delete", configNames, function(name)
		selectedDelete = name
	end)
	section:addButton("Delete Config", function()
		local name = selectedDelete
		if not (name and table.find(configNames, name)) then
			local typed = delDrop:Get()
			name = table.find(configNames, typed) and typed or nil
		end
		if not name then
			UI:notify("Select a config to delete first", "error")
			return
		end
		local path = cfgPath(name)
		local ok = pcall(function() delfile(path) end)
		if ok and isfile and isfile(path) then ok = false end

		if ok then
			local idx = table.find(configNames, name)
			while idx do
				table.remove(configNames, idx)
				idx = table.find(configNames, name)
			end
		else
			refreshConfigs()
		end

		selectedDelete = nil
		delDrop:Set(""); loadDrop:Set("")
		delDrop:Refresh(); loadDrop:Refresh()
		task.delay(0.15, function()
			delDrop:Refresh(); loadDrop:Refresh()
		end)

		if ok then
			UI:notify(ctx.dyn("deleted", name), "success")
		else
			UI:notify("Failed to delete config", "error")
		end
	end)
	section:addLabel("Type a name then press Save Config. Configs are saved permanently and appear in the Load dropdown. If nothing has been saved yet, the dropdown is empty.")
end}