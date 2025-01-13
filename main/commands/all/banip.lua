
local utils = require("utils.misc")
local userIp = require("objects.UserIp")
local UsersIpsService = require("database.services.UsersIpsService")
local command = {}
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


    -- permManager.dbManager:openConnection()
    -- local entries = permManager.dbManager:getAllEntry(userIps, {{"beammpid", beammpid}})
    -- permManager.dbManager:closeConnection()
    -- local count = 0
    -- for _, entry in pairs(entries) do
    --     count = count + 1
    --     local newUserIp = userIps.new(beammpid, entry.ip)
    --     newUserIp.is_banned = true
    --     permManager.dbManager:save(newUserIp)
    --     local target_id = utils.GetPlayerId(playername)
    --     if target_id ~= -1 then
    --         MP.DropPlayer(target_id, msgManager:GetMessage(sender_id, "moderation.ipbanned"))
    --     end
    -- end


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