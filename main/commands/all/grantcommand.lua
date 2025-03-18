
local utils = require("utils.misc")

local command = {
    args = {
        {name = "commandName", type = "string"},
        {name = "rolename", type = "string"}
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, commandName, rolename)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager


    if commandName == nil or rolename == nil then
        msgManager:SendMessage(sender_id, "commands.grantcommand.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    rolename = utils.capitalize(rolename)


    if sender_id ~= -2 then
        if not permManager:canManageRole(utils.getPlayerBeamMPID(sender_name), rolename) then
            msgManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
            return false
        end
    end



    local result = permManager:assignCommand(commandName, rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
    return true
end

return command