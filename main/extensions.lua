ExtensionsManager = {}

function ExtensionsManager.init()
    local extensionsPath = Utils.script_path() .. "extensions"
    local dirs = FS.ListDirectories(extensionsPath)
    local loadedExtensions = {}

    -- Protect Nickel Core before loading extensions
    if Nickel.ProtectCore then Nickel.ProtectCore() end

    if dirs then
        for _, dir in pairs(dirs) do
            local manifestPath = extensionsPath .. "/" .. dir .. "/ext_manifest.lua"
            local eventCatPath = extensionsPath .. "/" .. dir .. "/events"
            local eventCats = FS.ListDirectories(eventCatPath)

            local isEnabled = true
            if FS.Exists(manifestPath) then
                isEnabled = Nickel.IsExtensionEnabled(manifestPath)
            end

            if isEnabled then
                --loop in the events folder
                for _, eventcat in pairs(eventCats) do
                    ExtensionsManager.eventDispatcher.load(eventcat, dir)
                    Utils.nkprint("Loaded events for extension: " .. dir .. " in category: " .. eventcat, "info")
                end
                if FS.Exists(manifestPath) then
                    Nickel.LoadManifest(manifestPath, false, true) -- useProtection = true
                    table.insert(loadedExtensions, dir)
                    Utils.nkprint("Extension loaded: " .. dir, "info")
                end
            else
                Utils.nkprint("Extension disabled: " .. dir, "info")
            end
        end
    end

    if #loadedExtensions > 0 then
        Utils.nkprint("Extensions loaded (" .. #loadedExtensions .. "): " .. table.concat(loadedExtensions, ", "), "info")
    else
        Utils.nkprint("No extensions found or loaded.", "warn")
    end
    DatabaseManager:syncSchemas()
end

function ExtensionsManager.reloadExtension(extensionName)
    local extensionsPath = Utils.script_path() .. "extensions"
    local eventCatPath = extensionsPath .. "/" .. extensionName .. "/events"
    local eventCats = FS.ListDirectories(eventCatPath)

    if eventCats then
        for _, eventcat in pairs(eventCats) do
            ExtensionsManager.eventDispatcher.load(eventcat, extensionName)
            Utils.nkprint("Reloaded events for extension: " .. extensionName .. " in category: " .. eventcat, "info")
        end
    end
end




ExtensionsManager.eventDispatcher = {}

function ExtensionsManager.eventDispatcher.load(eventCategory, extensionName)
    local extensionsPath = Utils.script_path() .. "extensions"
    local basePath = extensionsPath .. "/" .. extensionName .. "/events/" .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)

    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
        local config = nil
        
        for _, file in ipairs(files) do
            if FS.GetExtension(file) == ".lua" and FS.GetFilename(file) ~= "config.lua" then
                local filePath = eventPath .. "/" .. file
                local listener = Nickel.LoadExtensionFile(filePath)
                if type(listener) == "function" then
                    -- Directly register each listener using the new multi-handler system
                    local handlerName = extensionName .. "/" .. file
                    MP.RegisterEvent(eventName, listener, handlerName)
                    Utils.nkprint("[dispatcher] [" .. extensionName .. "]  Loaded listener: " .. handlerName .. " for event: " .. eventName, "debug")
                else
                    Utils.nkprint("[dispatcher] [" .. extensionName .. "]  Skipped non-function in " .. file, "warning")
                end
            elseif FS.GetFilename(file) == "config.lua" then
                local configPath = eventPath .. "/config.lua"
                config = Nickel.LoadExtensionFile(configPath)
                if type(config) == "table" and config.timer and config.interval then
                    Utils.nkprint("[dispatcher] [" .. extensionName .. "]  Loaded config for event: " .. eventName, "debug")
                else
                    config = nil -- Invalid config
                    Utils.nkprint("[dispatcher] [" .. extensionName .. "]  Invalid config for event: " .. eventName, "error")
                end
            end
        end

        if config and config.timer then
            MP.CreateEventTimer(eventName, config.interval)
            Utils.nkprint("[dispatcher] [" .. extensionName .. "]  Created timer for event: " .. eventName, "debug")
        end
    end
end

ExtensionsManager.configManager = {}
--config helper for extensions
function ExtensionsManager.configManager.loadConfig(defaultConfig, filename, extensionName)
    if not extensionName then
        local info = debug.getinfo(2, "S")
        if info and info.source then
            local path = info.source
            if path:sub(1, 1) == "@" then path = path:sub(2) end
            extensionName = path:match("[\\/]extensions[\\/]([^\\/]+)[\\/]")
        end
    end

    if not extensionName then
        Utils.nkprint("Failed to infer extension name for config loading.", "error")
        return
    end

    local configChanged = false
    local configPath = FS.ConcatPaths(Utils.script_path(), "extensions", extensionName, filename)
    
    local configData = {}
    if FS.Exists(configPath) then
        configData = TOML.decodeFromFile(configPath) or {}
    end
    
    local function mergeTables(existing, default)
        for k, v in pairs(default) do
            if existing[k] == nil then
                existing[k] = v
            elseif type(v) == "table" and type(existing[k]) == "table" then
                mergeTables(existing[k], v)
            end
        end
    end
    local function needsMerge(existing, default)
        if type(existing) ~= "table" or type(default) ~= "table" then
            return true
        end
        for k, v in pairs(default) do
            if existing[k] == nil then
                return true
            elseif type(v) == "table" then
                if needsMerge(existing[k], v) then
                    return true
                end
            end
        end
        return false
    end
    if needsMerge(configData, defaultConfig) then
        mergeTables(configData, defaultConfig)
        configChanged = true
    end
    local function recursiveCleanup(existing, default)
        local changed = false
        for key, value in pairs(existing) do
            if default[key] == nil then
                existing[key] = nil
                changed = true
            elseif type(value) == "table" and type(default[key]) == "table" then
                if recursiveCleanup(value, default[key]) then
                    changed = true
                end
            end
        end
        return changed
    end
    if recursiveCleanup(configData, defaultConfig) then
        configChanged = true
    end
    if configChanged then
        TOML.encodeToFile(configData, {
            file = configPath,
            overwrite = true
        })
    end

    local configInstance = {}
    configInstance.data = configData
    
    function configInstance.get(key)
        return configInstance.data[key]
    end

    function configInstance.set(key, value)
        configInstance.data[key] = value
        TOML.encodeToFile(configInstance.data, {
            file = configPath,
            overwrite = true
        })
    end

    return configInstance
end

ExtensionsManager.init()