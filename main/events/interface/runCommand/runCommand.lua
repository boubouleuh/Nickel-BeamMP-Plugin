local lastCallTime = {}
local cooldown = 2 -- Cooldown period in seconds
return Event(function(id, data)
    local currentTime = os.time()

    if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
        lastCallTime[id] = currentTime
        local finaldata = Util.JsonDecode(data)
        if finaldata and finaldata.command and finaldata.args then
            local argsString = table.concat(finaldata.args, " ")
            local fullCommand = ConfigManager.GetSetting("commands").prefix .. finaldata.command .. " " .. argsString
            CommandsManager:CreateCommand(id, fullCommand, true)
        end
    end
end)




