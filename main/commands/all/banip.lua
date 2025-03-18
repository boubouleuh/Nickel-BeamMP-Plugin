
local utils = require("utils.misc")
local userIp = require("objects.UserIp")
local UsersIpsService = require("database.services.UsersIpsService")
local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"}
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager


    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.banip.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false

    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = utils.getPlayerBeamMPID(playername)


    local usersIpsService = UsersIpsService.new(beammpid, dbManager)

    local count = usersIpsService:banAllIps()

    if count > 0 then
        msgManager:SendMessage(sender_id, "commands.banip.success", {Count = count, Player = playername})
    elseif usersIpsService:isIpBanned() then
        msgManager:SendMessage(sender_id, "moderation.alreadyipbanned", {Player = playername})
        return false
    else
        msgManager:SendMessage(sender_id, "commands.banip.no_registered", {Player = playername})
        return false
    end

    return true
end

return command