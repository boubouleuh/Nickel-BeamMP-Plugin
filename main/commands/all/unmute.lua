
local utils = require("utils.misc")
local userStatus = require("objects.UserStatus")
local userIps = require("objects.UserIps")

local command = {}

function command.init(sender_id, sender_name, managers, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.unmute.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    local beammpid = utils.getPlayerBeamMPID(playername)
    permManager.dbManager:openConnection()
    local userStatusClass = permManager.dbManager:getClassByBeammpId(userStatus, beammpid)
    permManager.dbManager:closeConnection()
    if userStatusClass ~= nil then
        if userStatusClass.status_type == "ismuted" and userStatusClass.is_status_value == 1 or userStatusClass.status_type == "istempmuted" and userStatusClass.is_status_value == 1 then

            userStatusClass.status_type = ""
            userStatusClass.is_status_value = false
            local result = dbManager:save(userStatusClass)
            msgManager:SendMessage(sender_id, "commands.unmute.success", playername)
            msgManager:SendMessage(sender_id, string.format("database.code.%s", result))

        else
            msgManager:SendMessage(sender_id, "moderation.not_muted", playername)
        end
    end

    return true
end

return command