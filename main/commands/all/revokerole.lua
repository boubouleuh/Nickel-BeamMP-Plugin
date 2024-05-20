
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, rolename, playername)

    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if rolename == nil or playername == nil then
        msgManager:SendMessage(sender_id, "commands.revokerole.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end


    local beammpid = utils.getPlayerBeamMPID(playername) --TODO check if the player does not exist and check permissions to run this command on users who is below the sender
    if beammpid ~= nil then

        if sender_id ~= -2 then
            if not permManager:canManage(utils.getPlayerBeamMPID(sender_name), utils.getPlayerBeamMPID(playername)) then
                msgManager:SendMessage(sender_id, "commands.permissions.insufficient.manage", playername)
                return false
            end
            if not permManager:canManageRole(utils.getPlayerBeamMPID(sender_name), rolename) then
                msgManager:SendMessage(sender_id, "commands.permissions.insufficient.addrole", rolename)
                return false
            end
        end
        local result = permManager:unassignRole(rolename, beammpid)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
        return true

    else
        msgManager:SendMessage(sender_id, string.format("player.not_found", playername))
    end
end

return command