
local utils = require("utils.misc")
local userStatus = require("objects.UserStatus")

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

    local beammpid = utils.getPlayerBeamMPID(playername)
    permManager.dbManager:openConnection()
    local userStatusClass = permManager.dbManager:getClassByBeammpId(userStatus, beammpid)
    permManager.dbManager:closeConnection()
    if userStatusClass ~= nil then
        if userStatusClass.status_type == "ismuted" and userStatusClass.is_status_value == 1 or userStatusClass.status_type == "istempmuted" and userStatusClass.is_status_value == 1 then
            msgManager:SendMessage(sender_id, "moderation.alreadymuted", playername)

        else
            userStatusClass.status_type = "ismuted"
            userStatusClass.is_status_value = true
            userStatusClass.reason = reason
            local result = dbManager:save(userStatusClass)
            local target_id = utils.GetPlayerId(playername)

            if target_id ~= -1 then
                msgManager:SendMessage(target_id, "moderation.muted", playername, reason)
            end
            msgManager:SendMessage(sender_id, "commands.mute.success", playername, reason)
            msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

        end
    end
    return true
end

return command