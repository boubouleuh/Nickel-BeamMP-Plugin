

local utils = require("utils.misc")
local Role = require("objects.Role")
local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers)
    ---@type PermissionsHandler
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    ---@type DatabaseManager
    local dbManager = managers.dbManager
    --get all roles without permManager
    local roles = dbManager:getAllEntry(Role)
    table.sort(roles, function(a, b) return a.permlvl > b.permlvl end)
    --send the same way as the help command
    for _, role in pairs(roles) do
        msgManager:SendMessage(sender_id, role.roleName .. " | " .. role.permlvl )
    end
    return true
    

end

return command