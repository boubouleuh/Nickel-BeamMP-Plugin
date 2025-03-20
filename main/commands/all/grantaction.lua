
local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")
local action = {
    args = {
        {name = "actionName", type = "string"},
        {name = "rolename", type = "string"}
    }
}
--- action
---@param managers managers
function action.init(sender_id, sender_name, managers, actionName, rolename)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager


    if actionName == nil or rolename == nil then
        msgManager:SendMessage(sender_id, "commands.grantaction.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    rolename = utils.capitalize(rolename)


    local result = permManager:assignAction(actionName, rolename)
    msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
    interfaceUtils.sendString(-1, "NKResetPlayerList", "")
    -- local onlineplayers = MP.GetPlayers()
    -- for id, player in pairs(onlineplayers) do
    --     interfaceUtils.sendPlayers(id, 0, managers.dbManager, managers.permManager)
    -- end

    return true
end

return action