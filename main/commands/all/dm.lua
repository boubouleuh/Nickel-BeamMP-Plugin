
local utils = require("utils.misc")


local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, target_name, message)

    local cfgManager = managers.cfgManager
    local msgManager = managers.msgManager

    if target_name == nil or message == nil then
        msgManager:SendMessage(sender_id, "commands.dm.missing_args", {Prefix = cfgManager.config.commands.prefix})
        return false
    end


    local target_id = utils.GetPlayerId(target_name)
    if target_id ~= -1 then
  
        if sender_id ~= target_id then
            msgManager:SendMessage(sender_id, "commands.dm.to", {Player = target_name, Message = message})
            msgManager:SendMessage(target_id, "commands.dm.from", {Player = sender_name, Message = message})
            
        else
            msgManager:SendMessage(sender_id, "commands.dm.cant_dm_yourself")
        end
    else
        msgManager:SendMessage(sender_id, "player.not_found", {Player = target_name})
    end

    return true

end

return command