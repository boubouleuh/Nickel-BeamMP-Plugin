EventDispatcher = {}

function EventDispatcher.load(eventCategory)
    local basePath = Utils.script_path() .. "main/events/" .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)

    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
        local config = nil
        
        for _, file in ipairs(files) do
            if FS.GetExtension(file) == ".lua" and FS.GetFilename(file) ~= "config.lua" then
                local filePath = eventPath .. "/" .. file
                local listener = dofile(filePath)
                if type(listener) == "function" then
                    -- Directly register each listener using the new multi-handler system
                    MP.RegisterEvent(eventName, listener, file)
                    Utils.nkprint("[dispatcher] Loaded listener: " .. file .. " for event: " .. eventName, "debug")
                else
                    Utils.nkprint("[dispatcher] Skipped non-function in " .. file, "warning")
                end
            elseif FS.GetFilename(file) == "config.lua" then
                local configPath = eventPath .. "/config.lua"
                config = dofile(configPath)
                if type(config) == "table" and config.timer and config.interval then
                    Utils.nkprint("[dispatcher] Loaded config for event: " .. eventName, "debug")
                else
                    config = nil -- Invalid config
                    Utils.nkprint("[dispatcher] Invalid config for event: " .. eventName, "error")
                end
            end
        end

        if config and config.timer then
            MP.CreateEventTimer(eventName, config.interval)
            Utils.nkprint("[dispatcher] Created timer for event: " .. eventName, "debug")
        end
    end
end

return EventDispatcher