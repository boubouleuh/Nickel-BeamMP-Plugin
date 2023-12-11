
local utils = require("utils.misc")


local command = {}

function command.init(sender_id, sender_name, msgManager, target_name, message)

    if target_name == nil or message == nil then
        msgManager:SendMessage(sender_id, "commands.dm.missing_args")
        return false
    end


    local target_id = utils.GetPlayerId(target_name)
    if target_id ~= -1 then
  
        if sender_id ~= target_id then
            msgManager:SendMessage(sender_id, "commands.dm.to", target_name, message)
            msgManager:SendMessage(target_id, "commands.dm.from", sender_name, message)
            
        else
            msgManager:SendMessage(sender_id, "commands.dm.cant_dm_yourself")
        end
    else
        msgManager:SendMessage(sender_id, "player.not_found", target_name)
    end

    return true

end

return command