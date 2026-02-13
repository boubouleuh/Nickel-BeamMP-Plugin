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

            local isEnabled = true
            if FS.Exists(manifestPath) then
                isEnabled = Nickel.IsExtensionEnabled(manifestPath)
            end

            if isEnabled then
                if FS.Exists(manifestPath) then
                    Nickel.LoadManifest(manifestPath, false, true) -- useProtection = true
                    table.insert(loadedExtensions, dir)
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
end

ExtensionsManager.configManager = {}
--config helper for extensions
---@return ConfigInstance
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
    ---@class ConfigInstance
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