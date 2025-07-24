local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

return function(id, managers)
    if managers.cfgManager:GetSetting("client").interface then
        local onlineplayers = MP.GetPlayers()
        for id2, player in pairs(onlineplayers) do
            interfaceUtils.sendPlayer(id2, managers.dbManager, managers.permManager, managers.cfgManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
        end
    end
end