return function(env)
	local log, loader = env.log, env.loader
	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	local function progress(pct, text)
		if loader then loader.set(pct, text) end
	end

	-- ===== Setting Up Files =====
	local sources = {}
	local function preload(path)
		log("Fetching " .. path)
		sources[path] = env.get(path)
		task.wait()
	end
	local function import(path)
		if not sources[path] then preload(path) end
		local fn, err = loadstring(sources[path])
		assert(fn, "Error in " .. path .. ": " .. tostring(err))
		return fn()
	end

	-- ===== Fetching Files =====
	local CACHE_DIR, CACHE_FILE = "xxg-cache", "xxg-cache/tree.json"
	local function discover()
		local out = {}
		if env.localDir then
			local base = env.localDir:gsub("\\", "/")
			if base:sub(-1) ~= "/" then base = base .. "/" end
			local function walk(dir)
				for _, p in ipairs(listfiles(dir)) do
					p = p:gsub("\\", "/")
					if isfolder(p) then
						walk(p)
					else
						local i = p:find(base, 1, true)
						table.insert(out, i and p:sub(i + #base) or p)
					end
				end
			end
			walk(base:sub(1, -2))
			return out
		end

		local r = env.repo
		local url = string.format("https://api.github.com/repos/%s/%s/git/trees/%s?recursive=1", r.owner, r.name, r.branch)
		local ok, body = pcall(env.http, url)
		if ok then
			local okJ, data = pcall(function() return HttpService:JSONDecode(body) end)
			if okJ and type(data) == "table" and type(data.tree) == "table" then
				for _, node in ipairs(data.tree) do
					if node.type == "blob" and node.path:match("%.lua$") then table.insert(out, node.path) end
				end
				if data.truncated then log("WARNING: file list truncated") end
				if writefile then
					pcall(function()
						if makefolder and isfolder and not isfolder(CACHE_DIR) then makefolder(CACHE_DIR) end
						writefile(CACHE_FILE, HttpService:JSONEncode(out))
					end)
				end
				return out
			end
		end
		log("GitHub API failed: " .. tostring(body))
		if isfile and readfile and isfile(CACHE_FILE) then
			local okC, cached = pcall(function() return HttpService:JSONDecode(readfile(CACHE_FILE)) end)
			if okC and type(cached) == "table" and #cached > 0 then
				log("Using cached file list")
				return cached
			end
		end
		error("Cannot list files from GitHub (" .. tostring(body):sub(1, 60) .. "). Wait a while, or set LOCAL_DIR in main.lua")
	end

	local function pretty(s)
		s = s:gsub("[_%-]+", " ")
		s = s:gsub("(%a)([%w]*)", function(a, b) return a:upper() .. b end)
		return s
	end

	-- ===== Fetching Files (0% - 60%) =====
	progress(3, "Listing files")
	local files = discover()
	local wanted = {}
	for _, p in ipairs(files) do
		if p == "config.lua" or p:match("^lib/") or p:match("^lang/") or p:match("^modules/") then
			table.insert(wanted, p)
		end
	end
	table.sort(wanted)
	assert(table.find(wanted, "config.lua"), "config.lua not found in repository")
	for i, path in ipairs(wanted) do
		progress(6 + (i - 1) / #wanted * 54, "Downloading " .. path)
		preload(path)
	end
	progress(60, "Files downloaded")
	log("All files downloaded (" .. #wanted .. ")")

	-- ===== Config, Lib, Lang =====
	local Cfg = import("config.lua")
	if loader then loader.setTitle(Cfg.Title or "XXG") end
	local D = Cfg.Defaults or {}

	progress(62, "Loading library")
	local L = {library = {}, page = {}, section = {}}
	local order = import("lib/index.lua")
	assert(table.find(order, "core/classes"), 'lib/index.lua tidak berisi "core/classes"')

	local loadOrder = {}
	for _, n in ipairs(order) do
		if n:match("^core/") then table.insert(loadOrder, n) end
	end
	for _, n in ipairs(order) do
		if not n:match("^core/") then table.insert(loadOrder, n) end
	end

	for _, name in ipairs(loadOrder) do
		log("Lib " .. name)
		local ok, err = pcall(function() import("lib/" .. name .. ".lua")(L) end)
		if not ok then
			error(string.format("lib/%s.lua -> %s", name, tostring(err)), 0)
		end
	end

	local required = {
		"Theme", "create", "tween", "apply", "corner", "stroke", "padding", "listLayout", "newLabel",
		"Surfaces", "themeHooks", "S", "resetState", "surface", "colorKey", "accentGradient", "accentOutline", "panelBg",
		"makeIcon", "popCard", "makeDraggable", "windowButton", "newRow", "AUTO_Y", "HOVER_SCALE",
	}
	local missing = {}
	for _, k in ipairs(required) do
		if L[k] == nil then table.insert(missing, k) end
	end
	if #missing > 0 then
		error("lib not complete: LOST" .. table.concat(missing, ", "), 0)
	end

	local langs, dyn = {}, {}
	for _, p in ipairs(wanted) do
		local code = p:match("^lang/([^/]+)/index%.lua$")
		if code then
			local def = import(p)
			table.insert(langs, {code = code, def = def})
			dyn[code] = def.dyn
		end
	end
	table.sort(langs, function(a, b)
		if a.code == "en" then return true end
		if b.code == "en" then return false end
		return (a.def.name or a.code) < (b.def.name or b.code)
	end)

	progress(64, "Creating window")
	log("Creating window")
	local UI = L.library.new(Cfg.Title, Cfg.Subtitle, Cfg.Version)
	UI:setBackgroundTransparency((D.Transparency or 40) / 100)
	for _, l in ipairs(langs) do
		UI:registerLanguage(l.code, l.def.name or l.code, l.def.strings)
	end

	local function dynText(key, ...)
		local code = UI:getLanguage()
		local text = (dyn[code] and dyn[code][key]) or (dyn.en and dyn.en[key]) or key
		return string.format(text, ...)
	end

	local ctx = {
		UI = UI, Theme = UI.Theme, Cfg = Cfg, dyn = dynText, import = import,
		modules = {}, keybinds = {}, shared = {},
	}

	-- ===== Read Modules / Create Tabs =====
	local tabFiles = {}
	for _, p in ipairs(wanted) do
		local folder, file = p:match("^modules/([^/]+)/([^/]+)%.lua$")
		if folder and folder:sub(1, 1) ~= "_" then
			tabFiles[folder] = tabFiles[folder] or {}
			table.insert(tabFiles[folder], {name = file, path = p})
		end
	end

	local tabOrder, seen = {}, {}
	for _, f in ipairs(Cfg.TabOrder or {}) do
		if tabFiles[f] and not seen[f] then
			seen[f] = true
			table.insert(tabOrder, f)
		end
	end
	local rest = {}
	for f in pairs(tabFiles) do
		if not seen[f] then table.insert(rest, f) end
	end
	table.sort(rest)
	for _, f in ipairs(rest) do table.insert(tabOrder, f) end

	local plan, total = {}, 0
	for _, folder in ipairs(tabOrder) do
		local list = {}
		for _, item in ipairs(tabFiles[folder]) do
			local ok, mod = pcall(import, item.path)
			if ok and type(mod) == "function" then mod = {build = mod} end
			if ok and type(mod) == "table" and type(mod.build) == "function" then
				mod.name, mod.path = item.name, item.path
				mod.order = mod.order or (item.name:sub(1, 1) == "_" and -100 or 1000)
				table.insert(list, mod)
			else
				log("Module " .. item.path .. " INVALID: " .. tostring(mod))
			end
		end
		table.sort(list, function(a, b)
			if a.order ~= b.order then return a.order < b.order end
			return a.name < b.name
		end)
		table.insert(plan, {folder = folder, title = pretty(folder), list = list})
		total = total + #list
	end

	local tabPages, firstPage = {}, nil
	local function getTab(title)
		if not tabPages[title] then
			tabPages[title] = UI:addPage(title)
			firstPage = firstPage or tabPages[title]
		end
		return tabPages[title]
	end
	ctx.getTab = getTab

	local done = 0
	for _, tab in ipairs(plan) do
		for _, mod in ipairs(tab.list) do
			progress(66 + done / math.max(total, 1) * 31, "Loading " .. tab.folder .. "/" .. mod.name)
			log("Module " .. mod.path)
			local ok, err = pcall(function()
				mod.build(ctx, (mod.page ~= false) and getTab(tab.title) or nil)
			end)
			if not ok then
				log("Module " .. mod.path .. " FAILED: " .. tostring(err))
				warn("[ControlPanel] " .. mod.path .. " gagal: " .. tostring(err))
				UI:notify("Failed to load module: " .. mod.name, "error")
			end
			done = done + 1
			task.wait()
		end
	end
	if firstPage then UI:SelectPage(firstPage) end

	progress(98, "Applying theme & language")
	UI:setTheme(D.Theme or "White")
	UI:setLanguage(D.Language or "English")

	UI.OnClose = function()
		for _, m in pairs(ctx.modules) do
			if m.prepareClose then pcall(m.prepareClose) end
		end
		RunService.Stepped:Wait()
		RunService.Stepped:Wait()
		for _, m in pairs(ctx.modules) do
			if m.shutdown then pcall(m.shutdown) end
		end
	end
	env.genv.XXG_Cleanup = function() UI:Close() end

	log("Done")
	if loader then task.spawn(loader.finish) end
end