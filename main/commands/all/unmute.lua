
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")
local userIps = require("objects.UserIps")

local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.unmute.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = utils.getPlayerBeamMPID(playername)

    local statusService = StatusService.new(beammpid, dbManager)

    if statusService:checkStatus("ismuted") or statusService:checkStatus("istempmuted") then

        statusService:removeStatus("ismuted")
        statusService:removeStatus("istempmuted")
        msgManager:SendMessage(sender_id, "commands.unmute.success", {Player = playername})
    else
        msgManager:SendMessage(sender_id, "moderation.not_muted", {Player = playername})
    end


    return true
end

return command