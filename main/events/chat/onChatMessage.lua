
local onChatMessage = {}
function onChatMessage.new(cmdManager)
    
    

    function onMessage(player_id, player_name, message)
            return cmdManager:CreateCommand(player_id, message, true, cmdManager.msgManager)
    end

    MP.RegisterEvent("onChatMessage", "onMessage")

end




return onChatMessage