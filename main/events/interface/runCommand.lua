local interface = require("main.client.initInterface")

local runcommand = {}
---@param managers managers
function runcommand.new(managers)

    local lastCallTime = {}
    local cooldown = 2 -- Cooldown period in seconds
    function runCommand(id, data)
        local currentTime = os.time()

        if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
            lastCallTime[id] = currentTime
            finaldata = Util.JsonDecode(data)
            local argsString = table.concat(finaldata.args, " ")
            managers.cmdManager:CreateCommand(id, managers.cfgManager:GetSetting("commands").prefix .. finaldata.command .. " " .. argsString, true)
        end
    end
    MP.RegisterEvent("runCommand", "runCommand")

end




return runcommand