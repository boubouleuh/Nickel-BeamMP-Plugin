
local registerPlayer = require("main.registerPlayer")
local onPlayerAuth = {}
function onPlayerAuth.new(dbmanager)

    function onAuth(player_name, player_role, is_guest, identifiers)
        registerPlayer.register(identifiers["beammp"], player_name, dbmanager)
    end
    MP.RegisterEvent("onPlayerAuth", "onAuth") -- registering our event for the timer

end




return onPlayerAuth