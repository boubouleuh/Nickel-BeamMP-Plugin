local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")
local sessionPlayerStorage = require("main.sessionPlayerStorage")
local onPlayerJoin = {}
---@param managers managers
function onPlayerJoin.new(managers) 
    function onJoin(id)
        local sessionStorage = sessionPlayerStorage:new(utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
        sessionStorage:set("synced", true)

        if managers.cfgManager:GetSetting("client").interface then
            local onlineplayers = MP.GetPlayers()
            for id2, player in pairs(onlineplayers) do
                interfaceUtils.sendPlayer(id2, managers.dbManager, managers.permManager, utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
            end
        end



        managers.msgManager:SendMessage(id, managers.cfgManager:GetSetting("misc").join_message, {Role = managers.permManager:GetHighestRole(utils.getPlayerBeamMPID(MP.GetPlayerName(id))).roleName, Player = MP.GetPlayerName(id)})
    end
    MP.RegisterEvent("onPlayerJoin", "onJoin")

end




return onPlayerJoin



