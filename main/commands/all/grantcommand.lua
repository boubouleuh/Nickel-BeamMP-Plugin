
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, commandName, rolename)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if commandName == nil or rolename == nil then
        msgManager:SendMessage(sender_id, "commands.grantcommand.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    local result = permManager:assignCommand(commandName, rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
    return true
end

return command