
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, commandName, rolename)

    local permManager = managers.permManager
    local msgManager = managers.msgManager

    local result = permManager:unassignCommand(commandName, rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
    return true
end

return command


