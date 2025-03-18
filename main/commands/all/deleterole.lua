local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

local command = {
    args = {
        {name = "rolename", type = "string"},
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, rolename)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if rolename == nil then
        msgManager:SendMessage(sender_id, "commands.deleterole.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    rolename = utils.capitalize(rolename)


    local result = permManager:removeRole(rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

    local onlineplayers = MP.GetPlayers()
    for id, player in pairs(onlineplayers) do
        interfaceUtils.sendPlayers(id, 0, managers.dbManager, managers.permManager)
    end
    
    return true
end

return command