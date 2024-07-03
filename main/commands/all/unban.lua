
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")
local userIps = require("objects.UserIps")
local UsersIpsService = require("database.services.UsersIpsService")

local command = {}

function command.init(sender_id, sender_name, managers, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.unban.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    local beammpid = utils.getPlayerBeamMPID(playername)

    local statusService = StatusService.new(beammpid, dbManager)
    local usersIpsService = UsersIpsService.new(beammpid, dbManager)

 
    if statusService:checkStatus("isbanned") or statusService:checkStatus("istempbanned") then

        statusService:removeStatus("isbanned")
        statusService:removeStatus("istempbanned")

        msgManager:SendMessage(sender_id, "commands.unban.success", playername)

    elseif not usersIpsService:isIpBanned() then
        msgManager:SendMessage(sender_id, "moderation.not_banned", playername)
    end


    if usersIpsService:isIpBanned() then
        local result = usersIpsService:unbanAllIps()
        msgManager:SendMessage(sender_id, "commands.unban.unbanip.success", result, playername)
    end


    return true
end

return command