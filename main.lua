local REPO = {owner = "graysxx", name = "xxg", branch = "main"}
local LOCAL_DIR = nil
local LOG_FILE = "xxg-log.txt"

if not game:IsLoaded() then game.Loaded:Wait() end

local genv = (getgenv and getgenv()) or _G
local BASE = string.format("https://raw.githubusercontent.com/%s/%s/%s/", REPO.owner, REPO.name, REPO.branch)

local logLines = {}
local function log(msg)
	table.insert(logLines, string.format("[%.2f] %s", os.clock(), msg))
	print("[xxg] " .. msg)
	if writefile then pcall(writefile, LOG_FILE, table.concat(logLines, "\n")) end
end

-- Clean Prev Instance
if genv.XXG_Cleanup then
	log("Cleaning up previous instance")
	pcall(genv.XXG_Cleanup)
	genv.XXG_Cleanup = nil
	task.wait(0.5)
end

local function http(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 0 then return body end
	local req = request or http_request or (syn and syn.request)
	if req then
		local ok2, res = pcall(req, {Url = url, Method = "GET", Headers = {["User-Agent"] = "xxg-panel"}})
		if ok2 and res and res.Body and (res.StatusCode == nil or res.StatusCode == 200) then return res.Body end
		error("HTTP " .. tostring(ok2 and res and res.StatusCode or res))
	end
	error(tostring(body))
end

local function get(path)
	local lastErr
	for _ = 1, 3 do
		local ok, src = pcall(function()
			if LOCAL_DIR then return readfile(LOCAL_DIR .. path) end
			return http(BASE .. path)
		end)
		if ok and type(src) == "string" and #src > 0 and not src:match("^404: Not Found") then return src end
		lastErr = src
		task.wait(0.4)
	end
	error("Failed to fetch " .. path .. ": " .. tostring(lastErr))
end

local function run(path)
	local fn, err = loadstring(get(path))
	assert(fn, "Error in " .. path .. ": " .. tostring(err))
	return fn()
end

local loader
pcall(function() loader = run("modulehandler/loading.lua")() end)

local ok, err = pcall(function()
	run("modulehandler/handler.lua")({
		repo = REPO, base = BASE, localDir = LOCAL_DIR, get = get, http = http,
		log = log, loader = loader, genv = genv,
	})
end)
if not ok then
	log("ERROR: " .. tostring(err))
	warn("[xxg] " .. tostring(err))
	if loader then loader.fail(err) end
end