
local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")
local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, rolename, playername)

    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager

    if rolename == nil or playername == nil then
        msgManager:SendMessage(sender_id, "commands.grantrole.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    rolename = utils.capitalize(rolename)

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end


    local beammpid = utils.getPlayerBeamMPID(playername) --TODO check if the player does not exist and check permissions to run this command on users who is below the sender

    if beammpid ~= nil then

        if sender_id ~= -2 then
            if not permManager:canManage(utils.getPlayerBeamMPID(sender_name), utils.getPlayerBeamMPID(playername)) then
                msgManager:SendMessage(sender_id, "commands.permissions.insufficient.manage", {Player = playername})
                return false
            end
            if not permManager:canManageRole(utils.getPlayerBeamMPID(sender_name), rolename) then
                msgManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
                return false
            end
        end
        local result = permManager:assignRole(rolename, beammpid)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))
        local onlineplayers = MP.GetPlayers()
        for id, player in pairs(onlineplayers) do
            interfaceUtils.sendPlayer(id, 0, managers.dbManager, permManager, beammpid)
        end
        return true
    else

        
        msgManager:SendMessage(sender_id, string.format("player.not_found", {Player = playername}))
    end
end

return command