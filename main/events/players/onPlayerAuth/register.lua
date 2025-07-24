
local registerPlayer = require("main.registerPlayer")
local interfaceUtils = require("main.client.interfaceUtils")

return function(player_name, player_role, is_guest, identifiers, managers)
    local result = registerPlayer.register(identifiers["beammp"], player_name, managers.permManager, managers.msgManager, managers.dbManager, managers.cfgManager, identifiers["ip"], is_guest)
    if result ~= nil then
        return result
    end
end