
local onChatMessage = {}
function onChatMessage.new(msgManager) 
    function onMessage(player_id, player_name, message)
        msgManager:sendMessage(player_id, "commands.permissions.insufficient") -- for test only
    end
    MP.RegisterEvent("onChatMessage", "onMessage")

end




return onChatMessage