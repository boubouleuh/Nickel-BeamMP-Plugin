
local legacy = require("main.legacy")

local command = {}

function command.init(sender_id, sender_name, managers)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
   
    legacy.importOldData(managers)
    msgManager:SendMessage(sender_id, "commands.importLegacyData.success")

    return true
end

return command