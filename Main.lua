local BASE = "https://raw.githubusercontent.com/graysxx/xxg/main/"
local LOCAL_DIR = nil

if not game:IsLoaded() then game.Loaded:Wait() end

local RunService = game:GetService("RunService")

local function import(path)
	local ok, src = pcall(function()
		if LOCAL_DIR then return readfile(LOCAL_DIR .. path) end
		return game:HttpGet(BASE .. path)
	end)
	assert(ok and type(src) == "string", "[ControlPanel] gagal mengambil " .. path .. ": " .. tostring(src))
	local fn, err = loadstring(src, "=" .. path)
	assert(fn, "[ControlPanel] error di " .. path .. ": " .. tostring(err))
	return fn()
end

local Cfg = import("Config.lua")
local Strings = import("Lang/Strings.lua")
local UILibrary = import("Library/UI.lua")
local D = Cfg.Defaults

local UI = UILibrary.new(Cfg.Title, Cfg.Subtitle, Cfg.Version)
UI:setBackgroundTransparency(D.Transparency / 100)
UI:addStrings(Strings.List)

local function L(key, ...)
	return string.format(Strings.Dyn[UI:getLanguage()][key], ...)
end

-- ctx dibagikan ke semua modul
local ctx = {UI = UI, Theme = UI.Theme, Cfg = Cfg, L = L, import = import, modules = {}, pages = {}}

-- muat modul sesuai urutan di Config. Modul yang error tidak mematikan modul lain.
for _, name in ipairs(Cfg.Modules) do
	local ok, err = pcall(function() import("Modules/" .. name .. ".lua")(ctx) end)
	if not ok then
		warn("[ControlPanel] modul " .. name .. " gagal: " .. tostring(err))
		UI:notify("Failed to load module: " .. name, "error")
	end
end

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