local userStatus = require("objects.UserStatus")
local utils = require("utils.misc")


local onChatMessage = {}
function onChatMessage.new(cmdManager)
    
    

    function onMessage(player_id, player_name, message)
            local dbManager = cmdManager.dbManager
            local beammpid = utils.getPlayerBeamMPID(player_name)
            dbManager:openConnection()
            local status = dbManager:getClassByBeammpId(userStatus, beammpid)
            dbManager:closeConnection()

            if status.status_type == "ismuted" or status.status_type == "istempmuted" then
                return 1
            end

            return cmdManager:CreateCommand(player_id, message, true)
    end

    MP.RegisterEvent("onChatMessage", "onMessage")

end




return onChatMessage