
local utils = require("utils.misc")
local userStatus = require("objects.UserStatus")
local StatusService = require("database.services.StatusService")
local command = {}

function command.init(sender_id, sender_name, managers, playername, reason)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager

    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.ban.missing_args", cfgManager.config.commands.prefix)
        return false
    elseif reason == nil then
        reason = msgManager:GetMessage(sender_id, "moderation.default_reason")
    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    
    local beammpid = utils.getPlayerBeamMPID(playername)

    local statusService = StatusService.new(beammpid, dbManager)


        if statusService:checkStatus("isbanned") or statusService:checkStatus("istempbanned") then
            msgManager:SendMessage(sender_id, "moderation.alreadybanned", playername)
        else

            local result = statusService:createStatus("isbanned", reason)

            local target_id = utils.GetPlayerId(playername)

            if target_id ~= -1 then
                MP.DropPlayer(target_id, msgManager:GetMessage(sender_id, "moderation.banned", reason))
            end
            msgManager:SendMessage(sender_id, "commands.ban.success", playername, reason)
            msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

        end
   
    return true
end

return command