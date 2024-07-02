local userStatus = require("objects.UserStatus")
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

local onChatMessage = {}
function onChatMessage.new(cmdManager)
    
    

    function onMessage(player_id, player_name, message)


       

            local dbManager = cmdManager.dbManager
   
            local beammpid = utils.getPlayerBeamMPID(player_name) --IMPORTANT NEXT FIX IS THE STATUS ! NEED TO USE statusService !! TODO


            local statusService = StatusService.new(beammpid, dbManager)

            if statusService:checkStatus("ismuted") or statusService:checkStatus("istempmuted") then

                if statusService:checkStatusTime("istempmuted") then
                    statusService:removeStatus("istempmuted")
                end

                return 1
            end


            return cmdManager:CreateCommand(player_id, message, true)
    end

    MP.RegisterEvent("onChatMessage", "onMessage")

end




return onChatMessage