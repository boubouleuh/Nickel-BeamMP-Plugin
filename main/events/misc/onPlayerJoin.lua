local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")

local onPlayerJoin = {}
---@param managers managers
function onPlayerJoin.new(managers) 
    function onJoin(id)

        interfaceUtils.sendPlayer(-1, managers.dbManager, managers.permManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))        
        managers.msgManager:SendMessage(id, managers.cfgManager:GetSetting("misc").join_message, {Role = managers.permManager:GetHighestRole(utils.getPlayerBeamMPID(MP.GetPlayerName(id))).roleName, Player = MP.GetPlayerName(id)})
    end
    MP.RegisterEvent("onPlayerJoin", "onJoin")

end




return onPlayerJoin



