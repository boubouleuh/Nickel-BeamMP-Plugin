local userStatus = require("objects.UserStatus")
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

return function(player_id, player_name, message, managers)
        local dbManager = managers.dbManager
        local cmdManager = managers.cmdManager
        local beammpid = utils.getPlayerBeamMPID(player_name)
        local statusService = StatusService.new(beammpid, dbManager)
        if statusService:checkStatus("ismuted") or statusService:checkStatus("istempmuted") then

            if statusService:checkStatusTime("istempmuted") then
                statusService:removeStatus("istempmuted")
            end

            return 1
        end

        return cmdManager:CreateCommand(player_id, message, true)
end