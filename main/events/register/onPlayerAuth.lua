
local registerPlayer = require("main.registerPlayer")
local onPlayerAuth = {}
function onPlayerAuth.new(dbmanager) 
    function onAuth(player_name, player_role, is_guest, identifiers)
        registerPlayer.register(identifiers["beammp"], player_name, dbmanager, identifiers["ip"])
    end
    MP.RegisterEvent("onPlayerAuth", "onAuth")

end




return onPlayerAuth