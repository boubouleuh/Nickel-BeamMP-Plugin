
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, grantORrevoke, rolename, playername)

    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local playerid = utils.GetPlayerId(playername)

    local beammpid = utils.getPlayerBeamMPID(playerid) --TODO check if the player does not exist and check permissions to run this command on users who is below the sender
    if grantORrevoke == "grant" then
        local result = permManager:assignRole(rolename, beammpid)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
        return true
    elseif grantORrevoke == "revoke" then
        local result = permManager:unassignRole(rolename, beammpid)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
        return true
    end

end

return command