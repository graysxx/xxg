local BASE = "https://raw.githubusercontent.com/graysxx/xxg/main/"
local LOCAL_DIR = nil
local LOG_FILE = "xxg-log.txt"

if not game:IsLoaded() then game.Loaded:Wait() end

local env = (getgenv and getgenv()) or _G
local RunService = game:GetService("RunService")

-- log
local logLines = {}
local function log(msg)
	table.insert(logLines, string.format("[%.2f] %s", os.clock(), msg))
	print("[xxg] " .. msg)
	if writefile then pcall(writefile, LOG_FILE, table.concat(logLines, "\n")) end
end

-- cleanup instance
if env.XXG_Cleanup then
	log("Cleaning up previous instance...")
	pcall(env.XXG_Cleanup)
	env.XXG_Cleanup = nil
	task.wait(0.5)
end

local sources = {}

local function fetch(path)
	local ok, src
	for _ = 1, 3 do
		ok, src = pcall(function()
			if LOCAL_DIR then return readfile(LOCAL_DIR .. path) end
			return game:HttpGet(BASE .. path)
		end)
		if ok and type(src) == "string" and #src > 0 and not src:match("^404: Not Found") then
			return src
		end
		task.wait(0.5)
	end
	error("Failed to fetch " .. path .. ": " .. tostring(src))
end

local function preload(path)
	log("Fetching " .. path)
	sources[path] = fetch(path)
	task.wait()
end

local function import(path)
	if not sources[path] then preload(path) end
	local fn, err = loadstring(sources[path])
	assert(fn, "error di " .. path .. ": " .. tostring(err))
	return fn()
end

 -- Load
local function main()
	log("Executing XXG Control Panel")

	preload("Config.lua")
local Cfg = import("Config.lua")
	preload("Lang/Strings.lua")
	preload("Library/UI.lua")
	for _, name in ipairs(Cfg.Modules) do preload("Modules/" .. name .. ".lua") end
	log("semua file terunduh")

	local Strings = import("Lang/Strings.lua")
	local UILibrary = import("Library/UI.lua")
	local D = Cfg.Defaults

	log("buat window")
	local UI = UILibrary.new(Cfg.Title, Cfg.Subtitle, Cfg.Version)
	UI:setBackgroundTransparency(D.Transparency / 100)
	UI:addStrings(Strings.List)

	local function L(key, ...)
		return string.format(Strings.Dyn[UI:getLanguage()][key], ...)
	end

	local ctx = {UI = UI, Theme = UI.Theme, Cfg = Cfg, L = L, import = import, modules = {}, pages = {}}

	for _, name in ipairs(Cfg.Modules) do
		log("modul " .. name)
		local ok, err = pcall(function() import("Modules/" .. name .. ".lua")(ctx) end)
		if not ok then
			log("modul " .. name .. " GAGAL: " .. tostring(err))
			warn("[ControlPanel] modul " .. name .. " FAILED: " .. tostring(err))
			UI:notify("Failed to load module: " .. name, "error")
		end
		task.wait()
	end

	log("Setting up Language & Theme")
	UI:setTheme(D.Theme)
	UI:setLanguage(D.Language)

	-- Close Panel
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

	env.XXG_Cleanup = function() UI:Close() end

	log("selesai")
end

local ok, err = pcall(main)
if not ok then
	log("ERROR: " .. tostring(err))
	warn("[xxg] " .. tostring(err))
end