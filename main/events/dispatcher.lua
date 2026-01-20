EventDispatcher = {}

function EventDispatcher.load(eventCategory)
    local basePath = Utils.script_path() .. "main/events/" .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)

    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
        local config = nil
        
        for _, file in ipairs(files) do
            if FS.GetExtension(file) == ".lua" then
                local filePath = eventPath .. "/" .. file
                local event = dofile(filePath)
                if event.valid then
                    if type(event.callback) == "function" then
                        -- Directly register each listener using the new multi-handler system
                        MP.RegisterEvent(eventName, event.callback, file)
                        if event.timer then
                            MP.CancelEventTimer(eventName)
                            MP.CreateEventTimer(eventName, event.interval)
                            Utils.nkprint("[dispatcher] Created timer for event: " .. eventName, "debug")
                        end
                        Utils.nkprint("[dispatcher] Loaded listener: " .. file .. " for event: " .. eventName, "debug")
                    else
                        Utils.nkprint("[dispatcher] Skipped non-function in " .. file, "warning")
                    end
                else
                    Utils.nkprint("[dispatcher] Skipped registering event in " .. file .. " due to conditions not met", "warning")
                end
            end
        end
    end
end

return EventDispatcher