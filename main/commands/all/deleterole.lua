local utils = require("utils.misc")

local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, rolename)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if rolename == nil then
        msgManager:SendMessage(sender_id, "commands.deleterole.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    rolename = utils.capitalize(rolename)


    local result = permManager:removeRole(rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
    return true
end

return command