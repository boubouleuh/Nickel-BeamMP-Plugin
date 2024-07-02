
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

local command = {}

function command.init(sender_id, sender_name, managers, playername, time, reason)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager

    if playername == nil or time == nil then
        msgManager:SendMessage(sender_id, "commands.tempmute.missing_args", cfgManager.config.commands.prefix)
        return false
    elseif reason == nil then
        reason = msgManager:GetMessage(sender_id, "moderation.default_reason")
    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    
    local timestamp = os.time() + utils.timeConverter(time)
    local end_date = os.date("%d/%m/%Y %H:%M:%S", timestamp)

    local beammpid = utils.getPlayerBeamMPID(playername)


    local statusService = StatusService.new(beammpid, dbManager)




    if statusService:checkStatus("ismuted") or statusService:checkStatus("istempmuted") then
        msgManager:SendMessage(sender_id, "moderation.alreadymuted", playername)

    else


        local result = statusService:createStatus("istempmuted", reason, timestamp)

        local target_id = utils.GetPlayerId(playername)

        if target_id ~= -1 then
            msgManager:SendMessage(target_id, "moderation.tempmuted", reason, end_date)
        end
        msgManager:SendMessage(sender_id, "commands.tempmute.success", playername, reason, end_date)
        msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

    end

    return true
end

return command