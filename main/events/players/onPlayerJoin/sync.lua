local utils = require("utils.misc")
local sessionPlayerStorage = require("main.sessionPlayerStorage")

return function(id, managers)
    local sessionStorage = sessionPlayerStorage:new(utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
    sessionStorage:set("synced", true)
end