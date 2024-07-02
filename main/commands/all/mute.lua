
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

local command = {}

function command.init(sender_id, sender_name, managers, playername, reason)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager

    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.mute.missing_args", cfgManager.config.commands.prefix)
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

    if statusService:checkStatus("ismuted") or statusService:checkStatus("istempmuted") then
        msgManager:SendMessage(sender_id, "moderation.alreadymuted", playername)
    else


        local result = statusService:createStatus("ismuted", reason)
        local target_id = utils.GetPlayerId(playername)

        if target_id ~= -1 then
            msgManager:SendMessage(target_id, "moderation.muted", reason)
        end
        msgManager:SendMessage(sender_id, "commands.mute.success", playername, reason)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

    end

    return true
end

return command