
local utils = require("utils.misc")

return function(id, managers)
    managers.msgManager:SendMessage(-1, managers.cfgManager:GetSetting("misc").join_message, {Role = managers.permManager:GetHighestRole(utils.getPlayerBeamMPID(MP.GetPlayerName(id))).roleName, Player = MP.GetPlayerName(id)})
end