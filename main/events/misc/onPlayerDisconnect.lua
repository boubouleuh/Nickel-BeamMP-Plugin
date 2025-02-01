local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

local onPlayerDisconnect = {}
---@param managers managers
function onPlayerDisconnect.new(managers) 
    function onDisconnect(id)

        local onlineplayers = MP.GetPlayers()
        for id, player in pairs(onlineplayers) do
            interfaceUtils.sendPlayer(id, managers.dbManager, managers.permManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
        end
    end
    MP.RegisterEvent("onPlayerDisconnect", "onDisconnect")

end




return onPlayerDisconnect


