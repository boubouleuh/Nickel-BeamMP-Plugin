local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

local onPlayerJoin = {}
function onPlayerJoin.new(managers) 
    function onJoin(id)

        interfaceUtils.sendPlayer(-1, managers.dbManager, managers.permManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))

    end
    MP.RegisterEvent("onPlayerJoin", "onJoin")

end




return onPlayerJoin



