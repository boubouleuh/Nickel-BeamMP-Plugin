
local utils = require("utils.misc")


local command = {}

function command.init(sender_id, target_name, message, msgManager)
    local target_id = utils.GetPlayerId(target_name)
    local sender_name = MP.GetPlayerName(sender_id)

    if target_id ~= -1 then
        if sender_id ~= target_id then
            
            msgManager:SendMessage(sender_id, "To -> " .. target_name .. " : " .. message)
            msgManager:SendMessage(sender_id, "From -> " .. sender_name .. " : " .. message)
            
        else
            msgManager:SendMessage(sender_id, "You cant dm yourself")
        end
    else
        msgManager:SendMessage(sender_id, "Player not found")
    end

end

return command