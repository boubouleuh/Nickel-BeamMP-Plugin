local globalEnv = _G
Nickel = {}
globalEnv.Nickel = Nickel

-- Snapshot globals to protect them during reload
local protectedGlobals = {}
for k, _ in pairs(globalEnv) do protectedGlobals[k] = true end

protectedGlobals["Nickel"] = true
protectedGlobals["Tree"] = true
protectedGlobals["_G"] = true

function Nickel.PreserveGlobal(name)
    if type(name) == "string" then
        protectedGlobals[name] = true
    end
end
Nickel.telemetry = false
Nickel.IsReloading = false
Nickel.https = {request = function(url)
    local response = ""

    if MP.GetOSName() == "Windows" then
        response = os.execute('powershell -Command "Invoke-WebRequest -Uri ' .. url .. ' -OutFile temp.txt"')
        else
            response = os.execute("wget -q -O temp.txt " .. url)
        end
        
        if response then
            local file = io.open("temp.txt", "rb")
            if not file then
                return "", 404
            end
            local content = file:read("*all")
            file:close()
            os.remove("temp.txt")
            return content, 200
        else
            return "", 404
        end
    end
,
post = function(url, body, headers)
    local response = ""

    if MP.GetOSName() == "Windows" then
        local bodyFile = io.open("nickel_temp_body.json", "w")
        if bodyFile then
            bodyFile:write(body)
            bodyFile:close()
            response = os.execute('powershell -Command "try { Invoke-WebRequest -Uri ' .. url .. ' -Method Post -InFile nickel_temp_body.json -ContentType \'application/json\' -OutFile temp.txt } catch { Write-Host $_ }"')
            os.remove("nickel_temp_body.json")
        else
            print("[Nickel] Failed to create temp body file")
            return "", 500
        end
    else
        local escapedBody = body:gsub("'", "'\\''")
        response = os.execute("wget -q --header='Content-Type: application/json' --post-data='" .. escapedBody .. "' '" .. url .. "' -O temp.txt")
    end

    if response then
        local file = io.open("temp.txt", "rb")
        if not file then
            return "", 404
        end
        local content = file:read("*all")
        file:close()
        os.remove("temp.txt")
        return content, 200
    else
        return "", 404
    end
end
}
-- get only the last lines of the log file to avoid sending too much data
function Nickel.getCurrentLogsContext()
    local logFilePath = "Server.log"
    local f = io.open(logFilePath, "r")
    if not f then return "" end

    local first_lines = {}
    local last_lines = {}
    local count = 0

    for line in f:lines() do
        count = count + 1
        if count <= 100 then
            table.insert(first_lines, line)
        end

        table.insert(last_lines, line)
        if #last_lines > 100 then
            table.remove(last_lines, 1)
        end
    end
    f:close()
    local result
    if count <= 100 then
        result = "\27[0m----[LOGS STARTING]----\n" .. table.concat(first_lines, "\n")
    else
        result = "\27[0m----[LOGS STARTING]----\n" .. table.concat(first_lines, "\n") .. "\n\27[0m----[LOGS BEFORE ERROR]----\n" .. table.concat(last_lines, "\n")
    end


    result = result:gsub("[^\n]*%[CHAT%][^\n]*\n", "\27[31m[CHAT MESSAGE TRUNCATED]\27[0m\n"):gsub("[^\n]*%|CHAT%][^\n]*\n", "\27[31m[CHAT MESSAGE TRUNCATED]\27[0m\n")
    return result
end
function Nickel.reportError(err)
        if Nickel.telemetry == false then return end
        local body = Util.JsonEncode({
            type = "error",
            message = err,
            version = Nickel.Version,
            os = MP.GetOSName(),
            instance_id = Nickel.InstanceID,
            logs = Nickel.getCurrentLogsContext()
        })
        local res, code = Nickel.https.post("https://nickel.bouboule.workers.dev/", body)
        print("^1[Nickel] Error reported to Nickel server with response code: " .. tostring(code) .. "^r")
        print("^1[Nickel] If you need support please join the discord https://discord.gg/h5P84FFw7B ^r")
end

function Nickel.heartbeat()
    if Nickel.telemetry == false then return end

    local body = Util.JsonEncode({
        type = "alive",
        version = Nickel.Version,
        os = MP.GetOSName(),
        instance_id = Nickel.InstanceID
    })
    local res, code = Nickel.https.post("https://nickel.bouboule.workers.dev/", body)
end

local originalPcall = pcall
function pcall(func, ...)
    local results = table.pack(xpcall(func, debug.traceback, ...))
    --if its an extension error dont report it
    if not results[1] then
        if not results[2]:find("extensions.lua") then
            Nickel.reportError(results[2])
        end
    end
    return table.unpack(results, 1, results.n)
end

local function getPath()
    local str = debug.getinfo(2, "S").source
    if str:sub(1, 1) == "@" then str = str:sub(2) end
    return str:match("(.*/)")
end
Nickel.Path = getPath()

local function generateID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function getInstanceID()
    local root = Nickel.Path:gsub("Tree/$", "")
    local idFile = root .. ".nickel_instance_id"
    local f = io.open(idFile, "r")
    if f then
        local id = f:read("*all")
        f:close()
        if id and #id > 0 then return id end
    end
    
    local newID = generateID()
    f = io.open(idFile, "w")
    if f then
        f:write(newID)
        f:close()
    end
    return newID
end

Nickel.InstanceID = getInstanceID()

function Nickel.GetGitVersion()
    local root = Nickel.Path:gsub("Tree/$", "")
    local headFile = io.open(root .. ".git/HEAD", "r")
    if not headFile then return "Unknown" end
    local head = headFile:read("*line")
    headFile:close()
    
    if head:match("ref: ") then
        local ref = head:sub(6)
        local refFile = io.open(root .. ".git/" .. ref, "r")
        if refFile then
            local hash = refFile:read("*line")
            refFile:close()
            return hash:sub(1, 7)
        end
    else
        return head:sub(1, 7)
    end
    return "Unknown"
end

function Nickel.LoadLib(path, func)
    local root = Nickel.Path:gsub("Tree/$", "")
    local ext = package.config:sub(1, 1) == "\\" and ".dll" or ".so"
    local full = root .. "lib/" .. path .. ext
    func = func or "luaopen_" .. (path:match(".*/([^/]+)$") or path):gsub("-", "_")
    
    local lib, err = package.loadlib(full, func)
    if not lib then 
        Nickel.reportError(err)
        return print("^1[Nickel] Lib Error: " .. full .. "\n" .. err .. "^r") 

    end
    return lib()
end

function Nickel.LoadDir(dir, isExtension)
    local files = FS.ListFiles(dir)
    if not files then return end
    for _, f in pairs(files) do
        if f ~= "." and f ~= ".." then
            local full = dir .. "/" .. f
            if FS.IsDirectory(full) then Nickel.LoadDir(full, isExtension)
            elseif f:sub(-4) == ".lua" then 
                if isExtension then
                    Nickel.LoadExtensionFile(full)
                else
                    local ok, err = pcall(dofile, full)
                    if not ok then
                        print("^1[Nickel] Error loading " .. full .. ": " .. tostring(err) .. "^r")
                    end
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
        -- Nickel.reportError(err) Nah dont report extensions errors since its probably user fault
        print("^1[Nickel] Error loading " .. path .. ": " .. err .. "^r")
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

function Nickel.LoadManifest(path, isMain, isExtension)
    if isMain then Nickel.ManifestPath = path end
    local env = setmetatable({}, { __index = globalEnv })
    local chunk = loadfile(path, "t", env)
    if not chunk then Nickel.reportError(err) return print("^1[Nickel] Manifest Error: " .. path .. "^r") end
    chunk()
    
    if isMain and env.version then
        Nickel.Version = env.version
    end

    local pluginRoot = Nickel.Path:gsub("Tree/$", "")
    local manifestDir = path:match("(.*/)") or pluginRoot

    if not env.enabled then return end
    
    for _, p in ipairs(env.server_scripts or {}) do
        local clean = p:gsub("^/", "")
        if clean:sub(-2) == "/*" then 
            local relativeDir = clean:sub(1, -3)
            local targetDir = manifestDir .. relativeDir
            Nickel.LoadDir(targetDir, isExtension)
        else 
            local f = manifestDir .. clean
            if FS.Exists(f) then 
                if isExtension then
                    Nickel.LoadExtensionFile(f)
                else
                    local ok, err = pcall(dofile, f)
                    if not ok then
                        print("^1[Nickel] Error loading " .. f .. ": " .. tostring(err) .. "^r")
                    end
                end
            end
        end
    end
end

local function loadMod(f)
    local c, e = loadfile(Nickel.Path .. f)
    if c then c(Nickel) else Nickel.reportError(e) print("^1[Nickel] Mod Error ("..f.."): " .. e .. "^r") end
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
    if Nickel.IsReloading then Nickel.ProtectCore() return end
    Nickel.IsReloading = true
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
    if Nickel.UnprotectCore then Nickel.UnprotectCore() end
    Nickel.IsReloading = false
    Nickel.ProtectCore()
end

-- Initial registration
MP.RegisterEvent("onFileChanged", "Nickel_HotReload")

-- Update protected globals to include everything loaded by init.lua
for k, _ in pairs(globalEnv) do protectedGlobals[k] = true end

-- File Watcher for new files (Polling)
local knownFiles = {}

local function scanRecursive(dir, list)
    local files = FS.ListFiles(dir)
    if (type(files) ~= "table") then return end
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
