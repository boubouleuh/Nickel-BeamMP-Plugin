local utils = require("utils.misc")
local sessionPlayerStorage = require("main.sessionPlayerStorage")

return function(id, managers)
    local beammpid = utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    sessionPlayerStorage.set(beammpid, "synced", true)
end