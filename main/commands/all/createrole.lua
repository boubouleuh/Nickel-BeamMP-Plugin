
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, rolename1, beforeOrAfter, rolename2)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    --TODO ;createrole NewRole before Owner
    --TODO ;createrole NewRole after Owner
end

return command