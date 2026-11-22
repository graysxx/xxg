-- Main.lua: satu-satunya file yang dijalankan user
local BASE = "https://raw.githubusercontent.com/graysxx/xxg/main/"
local LOCAL_DIR = nil -- isi "xxg-panel/" untuk tes dari folder workspace executor (tanpa internet)
local LOG_FILE = "xxg-log.txt" -- catatan progres, ada di folder workspace executor

if not game:IsLoaded() then game.Loaded:Wait() end

local env = (getgenv and getgenv()) or _G
local RunService = game:GetService("RunService")

-- catat progres ke file (tetap ada walau game force close)
local logLines = {}
local function log(msg)
	table.insert(logLines, string.format("[%.2f] %s", os.clock(), msg))
	print("[xxg] " .. msg)
	if writefile then pcall(writefile, LOG_FILE, table.concat(logLines, "\n")) end
end

-- matikan instance sebelumnya (kalau script dijalankan ulang) supaya tidak menumpuk
if env.XXG_Cleanup then
	log("membersihkan instance lama")
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
	error("gagal mengambil " .. path .. ": " .. tostring(src))
end

local function preload(path)
	log("ambil " .. path)
	sources[path] = fetch(path)
	task.wait() -- beri napas ke game di antara tiap request
end

local function import(path)
	if not sources[path] then preload(path) end
	local fn, err = loadstring(sources[path])
	assert(fn, "error di " .. path .. ": " .. tostring(err))
	return fn()
end

local function main()
	log("mulai")

	-- 1) unduh SEMUA file dulu, sebelum UI dibuat
	preload("Config.lua")
local Cfg = import("Config.lua")
	preload("Lang/Strings.lua")
	preload("Library/UI.lua")
	for _, name in ipairs(Cfg.Modules) do preload("Modules/" .. name .. ".lua") end
	log("semua file terunduh")

	-- 2) baru bangun UI
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

	-- muat modul sesuai urutan di Config. Modul yang error tidak mematikan modul lain.
	for _, name in ipairs(Cfg.Modules) do
		log("modul " .. name)
		local ok, err = pcall(function() import("Modules/" .. name .. ".lua")(ctx) end)
		if not ok then
			log("modul " .. name .. " GAGAL: " .. tostring(err))
			warn("[ControlPanel] modul " .. name .. " gagal: " .. tostring(err))
			UI:notify("Failed to load module: " .. name, "error")
		end
		task.wait() -- satu frame per modul, supaya tidak terjadi lonjakan beban
	end

	log("terapkan tema & bahasa")
	UI:setTheme(D.Theme)
	UI:setLanguage(D.Language)

	-- saat panel di-close (tombol X): hentikan semua fitur & putuskan koneksi
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

	-- dipanggil otomatis kalau script dijalankan ulang
	env.XXG_Cleanup = function() UI:Close() end

	log("selesai")
end

local ok, err = pcall(main)
if not ok then
	log("ERROR: " .. tostring(err))
	warn("[xxg] " .. tostring(err))
end