local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

local onPlayerDisconnect = {}
function onPlayerDisconnect.new(managers) 
    function onDisconnect(id)

        interfaceUtils.sendPlayer(-1, managers.dbManager, managers.permManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))

    end
    MP.RegisterEvent("onPlayerDisconnect", "onDisconnect")

end




return onPlayerDisconnect


