
local utils = require("utils.misc")
local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
    local commands = managers.commands
    
    local prefix = cfgManager:GetSetting("commands").prefix
    for command in pairs(commands) do
        msgManager:SendMessage(sender_id, prefix .. command .. " | " .. commands[command].description )
    end


    return true
end

return command