---@meta
local globalEnv = _G
Nickel = {}
globalEnv.Nickel = Nickel

-- Snapshot globals to protect them during reload
local protectedGlobals = {}
for k, _ in pairs(globalEnv) do protectedGlobals[k] = true end

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

function Nickel.LoadDir(dir, useProtection)
    local files = FS.ListFiles(dir)
    if not files then return end
    for _, f in pairs(files) do
        if f ~= "." and f ~= ".." then
            local full = dir .. "/" .. f
            if FS.IsDirectory(full) then Nickel.LoadDir(full, useProtection)
            elseif f:sub(-4) == ".lua" then 
                if useProtection then
                    Nickel.LoadExtensionFile(full)
                else
                    dofile(full)
                end
            end
        end
    end
end

function Nickel.LoadExtensionFile(path)
    local env = setmetatable({}, {
        __index = globalEnv,
        __newindex = function(t, k, v)
            if k == "Nickel" then
                print("^1[Nickel] Security Warning: Attempt to overwrite global 'Nickel' in " .. path .. "^r")
                return
            end
            
            if Nickel.IsGlobalProtected and Nickel.IsGlobalProtected(k) then
                print("^1[Nickel] Security Warning: Attempt to overwrite core global '" .. k .. "' in " .. path .. "^r")
                return
            end

            globalEnv[k] = v
        end
    })
    rawset(env, "_G", env)
    
    local chunk, err = loadfile(path, "t", env)
    if not chunk then 
        print("^1[Nickel] Error loading " .. path .. ": " .. tostring(err) .. "^r")
        return nil
    end
    return chunk()
end

function Nickel.IsExtensionEnabled(path)
    local env = setmetatable({}, { __index = globalEnv })
    local chunk = loadfile(path, "t", env)
    if not chunk then return false end
    pcall(chunk)
    return env.enabled
end

function Nickel.LoadManifest(path, isMain, useProtection)
    if isMain then Nickel.ManifestPath = path end
    local env = setmetatable({}, { __index = globalEnv })
    local chunk = loadfile(path, "t", env)
    if not chunk then return print("^1[Nickel] Manifest Error: " .. path .. "^r") end
    chunk()
    
    local pluginRoot = Nickel.Path:gsub("Tree/$", "")
    local manifestDir = path:match("(.*/)") or pluginRoot

    if not env.enabled then return end
    
    for _, p in ipairs(env.server_scripts or {}) do
        local clean = p:gsub("^/", "")
        if clean:sub(-2) == "/*" then 
            local relativeDir = clean:sub(1, -3)
            local targetDir = manifestDir .. relativeDir
            
            if FS.ListFiles(targetDir) then
                Nickel.LoadDir(targetDir, useProtection)
            else
                -- Fallback to plugin root (Legacy support)
                targetDir = pluginRoot .. relativeDir
                if FS.ListFiles(targetDir) then
                    Nickel.LoadDir(targetDir, useProtection)
                end
            end
        else 
            local f = manifestDir .. clean
            if FS.Exists(f) then 
                if useProtection then
                    Nickel.LoadExtensionFile(f)
                else
                    dofile(f)
                end
            else 
                -- Fallback to plugin root (Legacy support)
                local f_legacy = pluginRoot .. clean
                if FS.Exists(f_legacy) then 
                    if useProtection then
                        Nickel.LoadExtensionFile(f_legacy)
                    else
                        dofile(f_legacy)
                    end
                else
                    print("^3[Nickel] Missing: " .. f .. "^r") 
                end
            end
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
    local pathSafe = path:gsub("\\", "/")
    
    -- Security & Loop prevention
    if not pathSafe:find(root, 1, true) then return end
    
    if not path:match("%.lua$") then return end

    -- Debounce (2 seconds)
    local now = os.time()
    if os.difftime(now, lastReloadTime) < 2 then return end
    lastReloadTime = now

    -- Check for extension change
    local extName = pathSafe:match("/extensions/([^/]+)/")
    if extName then
        local manifest = root .. "extensions/" .. extName .. "/ext_manifest.lua"
        if FS.Exists(manifest) then
            print("^3[Nickel] Extension changed: " .. extName .. " -> Reloading extension...^r")
            Nickel.LoadManifest(manifest)
            -- Reload extension events
            if ExtensionsManager and ExtensionsManager.reloadExtension then
                ExtensionsManager.reloadExtension(extName)
            end
            return
        end
    end
    
    print("^3[Nickel] Core file changed: " .. path .. " -> Full Reloading...^r")
    Nickel.Reload()
end
_G.Nickel_HotReload = onFileChanged

function Nickel.Reload()
    print("^3[Nickel] Hot Reloading...^r")
    
    -- Unprotect BEFORE doing anything else
    if Nickel.UnprotectCore then Nickel.UnprotectCore() end

    -- Reset Globals (Clear anything not present at startup)
    for k, _ in pairs(globalEnv) do
        if not protectedGlobals[k] then
            globalEnv[k] = nil
        end
    end

    if Nickel.ResetEvents then Nickel.ResetEvents() end
    
    -- Re-load threads to restore the tick system
    loadMod("threads.lua")
    
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
for k, _ in pairs(globalEnv) do protectedGlobals[k] = true end

-- File Watcher for new files (Polling)
local knownFiles = {}

local function scanRecursive(dir, list)
    local files = FS.ListFiles(dir)
    if files then
        for _, f in pairs(files) do 
            if f:match("%.lua$") then
                list[dir .. "/" .. f] = true 
            end
        end
    end
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

-- Security: Protect Nickel Core
local protectedData = {}
local isProtected = false
local coreGlobals = {}

function Nickel.ProtectCore()
    if isProtected then return end
    
    -- Snapshot current globals as Core Globals
    coreGlobals = {}
    for k, _ in pairs(globalEnv) do
        coreGlobals[k] = true
    end
    
    -- Move all current Nickel members to protected storage
    for k, v in pairs(Nickel) do
        protectedData[k] = v
        Nickel[k] = nil
    end
    
    local mt = {
        __index = protectedData,
        __newindex = function(t, k, v)
            if protectedData[k] ~= nil then
                print("^1[Nickel] Security Warning: Attempt to overwrite core member 'Nickel." .. tostring(k) .. "'^r")
                return
            end
            protectedData[k] = v
        end,
        __pairs = function() return pairs(protectedData) end
        -- __metatable removed to allow UnprotectCore to work
    }
    
    setmetatable(Nickel, mt)
    isProtected = true
    print("^2[Nickel] Core Protected.^r")
end

function Nickel.UnprotectCore()
    if not isProtected then return end
    
    -- Remove metatable first
    setmetatable(Nickel, nil)
    
    -- Restore members from protected storage
    for k, v in pairs(protectedData) do
        Nickel[k] = v
    end
    
    protectedData = {}
    coreGlobals = {}
    isProtected = false
end

function Nickel.IsGlobalProtected(k)
    return coreGlobals[k]
end

return Nickel
