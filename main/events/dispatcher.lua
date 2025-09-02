EventDispatcher = {}

function EventDispatcher.load(eventCategory)
    local listenersByEvent = {}
    local basePath = Utils.script_path() .. "main/events/" .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)

    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
        listenersByEvent[eventName] = {}
        local config = nil
        local validconfig = false
        
        for _, file in ipairs(files) do
            if FS.GetExtension(file) == ".lua" and FS.GetFilename(file) ~= "config.lua" then
                local filePath = eventPath .. "/" .. file
                local listener = dofile(filePath)
                if type(listener) == "function" then
                    table.insert(listenersByEvent[eventName], listener)
                    Utils.nkprint("[dispatcher] Loaded listener: " .. file .. " for event: " .. eventName, "debug")
                else
                    Utils.nkprint("[dispatcher] Skipped non-function in " .. file, "warning")
                end
            elseif FS.GetFilename(file) == "config.lua" then
                local configPath = eventPath .. "/config.lua"
                config = dofile(configPath)
                if type(config) == "table" and config.timer and config.interval then
                    validconfig = true
                    Utils.nkprint("[dispatcher] Loaded config for event: " .. eventName, "debug")
                else
                    Utils.nkprint("[dispatcher] Invalid config for event: " .. eventName, "error")
                end
            else
                Utils.nkprint("[dispatcher] Skipped non-Lua file: " .. file, "warning")
            end
        end

        local funcName = "nickel_" .. eventCategory .. "_" .. eventName
        _G[funcName] = function(...)
            local args = {...}
            local result = nil
            for i, fn in ipairs(listenersByEvent[eventName]) do
                local ok, ret = pcall(fn, table.unpack(args))
                if not ok then
                    Utils.nkprint("[" .. eventName .. "] Listener error: " .. tostring(ret), "error")
                else
                    result = ret
                end
            end
            return result
        end

        MP.RegisterEvent(eventName, funcName)
        if validconfig and config.timer then
            MP.CreateEventTimer(eventName, config.interval)
            Utils.nkprint("[dispatcher] Created timer for event: " .. eventName, "debug")
        end
        Utils.nkprint("[dispatcher] Registered event: " .. eventName .. " > " .. funcName, "debug")
    end
end

return EventDispatcher