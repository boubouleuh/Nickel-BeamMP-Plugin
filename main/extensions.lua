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



ExtensionsManager.init()