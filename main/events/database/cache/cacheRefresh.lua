
local utils = require("utils.misc")
local sessionServerStorage = require("main.sessionServerStorage")
---@param managers managers
return function(managers, beammpidToUpdate)
    ---@type DatabaseManager
    local dbManager = managers.dbManager
    --Cache the online players database and the roles etc
    if dbManager.database_type == "mysql" then
        local dbUserCache = sessionServerStorage.get("Players") or {}
        if beammpidToUpdate ~= nil then
            dbUserCache[beammpidToUpdate] = dbManager:getUserWithRoles(beammpidToUpdate, managers.permManager, false)
            sessionServerStorage.set("Players", dbUserCache)
            return
        end
        local onlinePlayers = MP.GetPlayers()
        for id, v in pairs(onlinePlayers) do
            local beammpid = utils.getPlayerBeamMPID(v)
            dbUserCache[beammpid] = dbManager:getUserWithRoles(beammpid, managers.permManager, false)
        end

        sessionServerStorage.set("Players", dbUserCache)
    end
end

