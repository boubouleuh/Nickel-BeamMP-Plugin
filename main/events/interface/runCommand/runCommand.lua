local interface = require("main.client.initInterface")

local lastCallTime = {}
local cooldown = 2 -- Cooldown period in seconds
---@param managers managers
return function(id, data, managers)


        local currentTime = os.time()

        if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
            lastCallTime[id] = currentTime
            local finaldata = Util.JsonDecode(data)
            local argsString = table.concat(finaldata.args, " ")
            managers.cmdManager:CreateCommand(id, managers.cfgManager:GetSetting("commands").prefix .. finaldata.command .. " " .. argsString, true)
        end
  

end




