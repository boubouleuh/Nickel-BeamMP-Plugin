EventDispatcher = {}
EventDispatcher.paths = {}

local function getCaller(info)
    local source = info.source
    local callerType = "Unknown"
    local callerName = "Unknown"
    if source:sub(1, 1) == "@" then
        source = source:sub(2)
    end
    if source:find("extensions") then
        callerType = "Extension"
        callerName = source:match("extensions[\\/]([^\\/]+)[\\/]") or "Unknown Extension"
    else
        callerType = "Core"
        callerName = "Nickel"
    end
    return callerType, callerName
end

function EventDispatcher.setPath(path)
    local info = debug.getinfo(2, "S")
    local callerType, callerName = getCaller(info)
    EventDispatcher.paths[callerName] = {callerType = callerType, path = path}
end



function EventDispatcher.load(eventCategory)
    local info = debug.getinfo(2, "S")
    local callerType, callerName = getCaller(info)
    local basePath = EventDispatcher.paths[callerName].path .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)
    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
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
                            Utils.nkprint("[dispatcher][" .. callerType .. "-" .. callerName .. "] Created timer for event: " .. eventName, "debug")
                        end
                        Utils.nkprint("[dispatcher][" .. callerType .. "-" .. callerName .. "] Loaded listener: " .. file .. " for event: " .. eventName, "debug")
                    else
                        Utils.nkprint("[dispatcher][" ..  callerType .. "-" .. callerName .. "] Skipped non-function in " .. file, "warning")
                    end
                else
                    Utils.nkprint("[dispatcher][" .. callerType .. "-" .. callerName .. "] Skipped registering event in " .. file .. " due to conditions not met", "warning")
                end
            end
        end
    end
end

return EventDispatcher