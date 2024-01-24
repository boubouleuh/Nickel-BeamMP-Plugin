
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, rolename, playername)

    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if rolename == nil or playername == nil then
        msgManager:SendMessage(sender_id, "commands.grantrole.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    local playerid = utils.GetPlayerId(playername)

    local beammpid = utils.getPlayerBeamMPID(playerid) --TODO check if the player does not exist and check permissions to run this command on users who is below the sender
    if beammpid ~= nil then

        local result = permManager:assignRole(rolename, beammpid)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
        return true
    else
        msgManager:SendMessage(sender_id, string.format("player.not_found", playername))
    end
end

return command