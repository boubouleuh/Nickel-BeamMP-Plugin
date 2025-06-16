
local registerPlayer = require("main.registerPlayer")
local interfaceUtils = require("main.client.interfaceUtils")
local onPlayerAuth = {}
function onPlayerAuth.new(permManager, msgManager, dbManager, cfgManager)
    function onAuth(player_name, player_role, is_guest, identifiers)
        local result = registerPlayer.register(identifiers["beammp"], player_name, permManager, msgManager, dbManager, cfgManager, identifiers["ip"], is_guest)
        if result ~= nil then
            return result
        end
    end
    MP.RegisterEvent("onPlayerAuth", "onAuth")

end




return onPlayerAuth