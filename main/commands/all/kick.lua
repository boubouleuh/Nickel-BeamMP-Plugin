
local utils = require("utils.misc")
local userStatus = require("objects.UserStatus")

local command = {
    type = "user"
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, playername, reason)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager


    if playername == nil then
        msgManager:SendMessage(sender_id, "commands.kick.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    elseif reason == nil then
        reason = msgManager:GetMessage(sender_id, "moderation.default_reason")
    end

    local target_id = utils.GetPlayerId(playername)

    if target_id ~= -1 then
        MP.DropPlayer(target_id, reason)
    end
    msgManager:SendMessage(sender_id, "commands.kick.success", {Player = playername, Reason = reason})

    return true
end

return command