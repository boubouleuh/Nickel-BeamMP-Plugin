
local registerPlayer = require("main.registerPlayer")
local onPlayerAuth = {}
function onPlayerAuth.new(permManager) 
    function onAuth(player_name, player_role, is_guest, identifiers)
        local result = registerPlayer.register(identifiers["beammp"], player_name, permManager, identifiers["ip"])
        if result ~= nil then
            return result
        end
    end
    MP.RegisterEvent("onPlayerAuth", "onAuth")

end




return onPlayerAuth