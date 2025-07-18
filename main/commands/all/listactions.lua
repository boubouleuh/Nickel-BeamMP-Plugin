local utils = require("utils.misc")
local Action = require("objects.Action")
local command = {
    type="global",
    args = {
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers)
    ---@type PermissionsHandler
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    ---@type DatabaseManager
    local dbManager = managers.dbManager
    --get all actions
    local actions = dbManager:withConnection(function()
        return dbManager:getAllEntry(Action)
    end)
    --send the same way as the help command
    for _, action in pairs(actions) do
        msgManager:SendMessage(sender_id, action.actionName)
    end
    return true
    

end

return command