
local utils = require("utils.misc")
local userStatus = require("objects.UserStatus")

local command = {}

function command.init(sender_id, sender_name, managers, playername, time, reason)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager

    if playername == nil or time == nil then
        msgManager:SendMessage(sender_id, "commands.tempban.missing_args", cfgManager.config.commands.prefix)
        return false
    elseif reason == nil then
        reason = msgManager:GetMessage(sender_id, "moderation.default_reason")
    end

    local timestamp = os.time() + utils.timeConverter(time)
    local end_date = os.date("%d/%m/%Y %H:%M:%S", timestamp)

    local beammpid = utils.getPlayerBeamMPID(playername)
    permManager.dbManager:openConnection()
    local userStatusClass = permManager.dbManager:getClassByBeammpId(userStatus, beammpid)
    permManager.dbManager:closeConnection()
    if userStatusClass ~= nil then
        if userStatusClass.status_type == "isbanned" and userStatusClass.is_status_value == 1 or userStatusClass.status_type == "istempbanned" and userStatusClass.is_status_value == 1 then
            msgManager:SendMessage(sender_id, "moderation.alreadybanned", playername)

        else
            userStatusClass.status_type = "istempbanned"
            userStatusClass.is_status_value = true
            userStatusClass.reason = reason
            userStatusClass.time = timestamp
            local result = dbManager:save(userStatusClass)
            local target_id = utils.GetPlayerId(playername)

            if target_id ~= -1 then
                MP.DropPlayer(target_id, reason .. " " .. msgManager:GetMessage(sender_id, "moderation.tempbanned", end_date))
            end
            msgManager:SendMessage(sender_id, "commands.ban.success", playername, reason)
            msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

        end
    end
    return true
end

return command