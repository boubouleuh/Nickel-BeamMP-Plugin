
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")
local UsersIpsService = require("database.services.UsersIpsService")

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"},
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
        msgManager:SendMessage(sender_id, "commands.unban.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    local beammpid = utils.getPlayerBeamMPID(playername)

    local statusService = StatusService.new(beammpid, dbManager)
    local usersIpsService = UsersIpsService.new(beammpid, dbManager)

 
    if statusService:checkStatus("isbanned") or statusService:checkStatus("istempbanned") then

        
        statusService:disableStatus("isbanned")
        statusService:disableStatus("istempbanned")

        msgManager:SendMessage(sender_id, "commands.unban.success", {Player = playername})

    elseif not usersIpsService:isIpBanned() then
        msgManager:SendMessage(sender_id, "moderation.not_banned", {Player = playername})
    end


    if usersIpsService:isIpBanned() then
        local result = usersIpsService:unbanAllIps()
        msgManager:SendMessage(sender_id, "commands.unban.unbanip.success", {Count = result, Player = playername})
    end


    return true
end

return command