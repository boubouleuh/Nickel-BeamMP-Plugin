
local registerPlayer = require("main.registerPlayer")
local interfaceUtils = require("main.client.interfaceUtils")
local onPlayerAuth = {}
function onPlayerAuth.new(permManager, msgManager)
    function onAuth(player_name, player_role, is_guest, identifiers)
        local result = registerPlayer.register(identifiers["beammp"], player_name, permManager, identifiers["ip"], msgManager, is_guest)

        -- local onlineplayers = MP.GetPlayers()
        -- for id, player in pairs(onlineplayers) do
        --     interfaceUtils.sendPlayer(id, permManager.dbManager, permManager, identifiers["beammp"])
        -- end

        if result ~= nil then
            return result
        end
    end
    MP.RegisterEvent("onPlayerAuth", "onAuth")

end




return onPlayerAuth