local utils = require("utils.misc")
local dispatch = {}

function dispatch.load(eventCategory, managers)
    local listenersByEvent = {}
    local basePath = utils.script_path() .. "main/events/" .. eventCategory .. "/"
    local eventDirs = FS.ListDirectories(basePath)

    for _, eventName in ipairs(eventDirs) do
        local eventPath = basePath .. eventName
        local files = FS.ListFiles(eventPath)
        listenersByEvent[eventName] = {}
        local config = nil
        local validconfig = false
        for _, file in ipairs(files) do
            if FS.GetExtension(file) == ".lua" and FS.GetFilename(file) ~= "config.lua" then
                local modulePath = "main.events." .. eventCategory .. "." .. eventName .. "." .. file:gsub("%.lua$", "")
                local listener = require(modulePath)
                if type(listener) == "function" then
                    table.insert(listenersByEvent[eventName], listener)
                else
                    utils.nkprint("[dispatcher] Skipped non-function in " .. modulePath, "warning")
                end
            elseif FS.GetFilename(file) == "config.lua" then
                local configPath = "main.events." .. eventCategory .. "." .. eventName .. ".config"
                config = require(configPath)
                if type(config) == "table" and config.timer and config.interval then
                    validconfig = true
                    utils.nkprint("[dispatcher] Loaded config for event: " .. eventName, "debug")
                else
                    utils.nkprint("[dispatcher] Invalid config for event: " .. eventName, "error")
                end
            else
                utils.nkprint("[dispatcher] Skipped non-Lua file: " .. file, "warning")
            end
        end

        local funcName = "nickel_" .. eventCategory .. "_" .. eventName
        _G[funcName] = function(...)
            local args = {...}
            table.insert(args, managers)
            local result = nil
            for i, fn in ipairs(listenersByEvent[eventName]) do
                local ok, ret = pcall(fn, table.unpack(args))
                if not ok then
                    utils.nkprint("[" .. eventName .. "] Listener error: " .. tostring(ret), "error")
                else
                    result = ret
                end
            end
            return result
        end

        MP.RegisterEvent(eventName, funcName)
        if validconfig and config.timer then
            MP.CreateEventTimer(eventName, config.interval)
            utils.nkprint("[dispatcher] Created timer for event: " .. eventName, "debug")
        end
        utils.nkprint("[dispatcher] Registered event: " .. eventName .. " > " .. funcName, "debug")
    end
end

return dispatch