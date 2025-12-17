---@meta
local Nickel = {}
_G.Nickel = Nickel

-- Snapshot globals to protect them during reload
local protectedGlobals = {}
for k, _ in pairs(_G) do protectedGlobals[k] = true end

protectedGlobals["Nickel"] = true
protectedGlobals["Tree"] = true
protectedGlobals["_G"] = true

local function getPath()
    local str = debug.getinfo(2, "S").source
    if str:sub(1, 1) == "@" then str = str:sub(2) end
    return str:match("(.*/)")
end
Nickel.Path = getPath()

function Nickel.LoadLib(path, func)
    local root = Nickel.Path:gsub("Tree/$", "")
    local ext = package.config:sub(1, 1) == "\\" and ".dll" or ".so"
    local full = root .. "lib/" .. path .. ext
    func = func or "luaopen_" .. (path:match(".*/([^/]+)$") or path):gsub("-", "_")
    
    local lib, err = package.loadlib(full, func)
    if not lib then return print("^1[Nickel] Lib Error: " .. full .. "\n" .. tostring(err) .. "^r") end
    return lib()
end

function Nickel.LoadDir(dir)
    local files = FS.ListFiles(dir)
    if not files then return end
    for _, f in pairs(files) do
        local full = dir .. "/" .. f
        if FS.IsDirectory(full) then Nickel.LoadDir(full)
        elseif f:sub(-4) == ".lua" then dofile(full) end
    end
end

function Nickel.LoadManifest(path)
    Nickel.ManifestPath = path
    local env = {}
    local chunk = loadfile(path, "t", env)
    if not chunk then return print("^1[Nickel] Manifest Error: " .. path .. "^r") end
    chunk()
    
    local root = Nickel.Path:gsub("Tree/$", "")
    for _, p in ipairs(env.server_scripts or {}) do
        local clean = p:gsub("^/", "")
        if clean:sub(-2) == "/*" then Nickel.LoadDir(root .. clean:sub(1, -3))
        else 
            local f = root .. clean
            if FS.Exists(f) then dofile(f) else print("^3[Nickel] Missing: " .. f .. "^r") end
        end
    end
end

local function loadMod(f)
    local c, e = loadfile(Nickel.Path .. f)
    if c then c(Nickel) else print("^1[Nickel] Mod Error ("..f.."): " .. tostring(e) .. "^r") end
end

loadMod("events.lua")
loadMod("threads.lua")
loadMod("colors.lua")

-- Hot Reload Logic
local lastReloadTime = 0
local function onFileChanged(path)
    local root = Nickel.Path:gsub("Tree/$", "")
    path = path:gsub("\\", "/")
    
    -- Security & Loop prevention
    if not path:find(root, 1, true) then return end
    if path:match("%.log$") or path:match("%.json$") or path:match("%.toml$") then return end
    if path:match("temp_file") then return end
    if path:match("%.db$") or path:match("%.sqlite") then return end -- Ignore DB writes
    if path:match("%.git") then return end

    -- Debounce (2 seconds)
    local now = os.time()
    if os.difftime(now, lastReloadTime) < 2 then return end
    
    print("^3[Nickel] File changed: " .. path .. " -> Reloading...^r")
    lastReloadTime = now
    
    -- Delay slightly to ensure file write is complete? No, usually fine.
    Nickel.Reload()
end
_G.Nickel_HotReload = onFileChanged

function Nickel.Reload()
    print("^3[Nickel] Hot Reloading...^r")
    
    -- Reset Globals (Clear anything not present at startup)
    for k, _ in pairs(_G) do
        if not protectedGlobals[k] then
            _G[k] = nil
        end
    end

    if Nickel.ResetEvents then Nickel.ResetEvents() end
    
    -- Re-register hot reload listener as ResetEvents cleared it
    MP.RegisterEvent("onFileChanged", "Nickel_HotReload")
    
    if Nickel.ManifestPath then
        Nickel.LoadManifest(Nickel.ManifestPath)
    end

    -- Trigger onInit after reload
    if Nickel.TriggerEvent then Nickel.TriggerEvent("onInit") end

    print("^2[Nickel] Reload Complete.^r")
end

-- Initial registration
MP.RegisterEvent("onFileChanged", "Nickel_HotReload")

-- Update protected globals to include everything loaded by init.lua
for k, _ in pairs(_G) do protectedGlobals[k] = true end

-- File Watcher for new files (Polling)
local knownFiles = {}

local function scanRecursive(dir, list)
    -- Files
    local files = FS.ListFiles(dir)
    if files then
        for _, f in pairs(files) do 
            if f:match("%.lua$") then
                list[dir .. "/" .. f] = true 
            end
        end
    end
    -- Directories
    local dirs = FS.ListDirectories(dir)
    if dirs then
        for _, d in pairs(dirs) do scanRecursive(dir .. "/" .. d, list) end
    end
end

local function initFileWatcher()
    local root = Nickel.Path:gsub("Tree/$", "")
    scanRecursive(root, knownFiles)
    
    local function poll()
        local current = {}
        scanRecursive(root, current)
        
        local changeDetected = false
        
        -- Check for new files
        for path, _ in pairs(current) do
            if not knownFiles[path] then
                if path:match("%.lua$") then
                    print("^3[Nickel] New file: " .. path .. " -> Reloading...^r")
                    changeDetected = true
                    break
                end
            end
        end
        
        -- Check for deleted files
        if not changeDetected then
            for path, _ in pairs(knownFiles) do
                if not current[path] then
                    if path:match("%.lua$") then
                        print("^3[Nickel] File deleted: " .. path .. " -> Reloading...^r")
                        changeDetected = true
                        break
                    end
                end
            end
        end
        
        knownFiles = current
        
        if changeDetected then
            Nickel.Reload()
        end

        if Nickel.SetTimeout then Nickel.SetTimeout(2000, poll) end
    end
    if Nickel.SetTimeout then Nickel.SetTimeout(2000, poll) end
end
initFileWatcher()

return Nickel
