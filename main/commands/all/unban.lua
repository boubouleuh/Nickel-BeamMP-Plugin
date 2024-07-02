
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")
local userIps = require("objects.UserIps")

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

 
    if statusService:checkStatus("isbanned") or statusService:checkStatus("istempbanned") then

        statusService:removeStatus("isbanned")
        statusService:removeStatus("istempbanned")

        msgManager:SendMessage(sender_id, "commands.unban.success", playername)

    else
        msgManager:SendMessage(sender_id, "moderation.not_banned", playername)
    end


    permManager.dbManager:openConnection()
    local entries = permManager.dbManager:getAllEntry(userIps, {{"beammpid", beammpid}})
    permManager.dbManager:closeConnection()
    local count = 0
    for _, entry in pairs(entries) do
        count = count + 1
        local newUserIp = userIps.new(beammpid, entry.ip)
        newUserIp.is_banned = false
        permManager.dbManager:save(newUserIp)
    end

    return true
end

return command