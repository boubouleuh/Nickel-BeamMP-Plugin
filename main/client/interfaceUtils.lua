local Roles = require("objects.Role")
local usersService = require("database.services.UsersService")
local utils = {}
--- send a string to the client
---@param id integer
---@param event_name string
---@param data string   
function utils.sendString(id, event_name, data)
    MP.TriggerClientEvent(id, event_name, data) 
end

--- send a table to the client
---@param id integer
---@param event_name string
---@param data table   
function utils.sendTable(id, event_name, data)
    MP.TriggerClientEventJson(id, event_name, data)
end
--- send every players to client
---@param id integer
---@param offset integer
---@param dbManager DatabaseManager
function utils.sendPlayers(id, offset, dbManager)
    dbManager:openConnection()
    local onlineplayers = MP.GetPlayers()
    local players = dbManager:getUsersDynamically(150, offset, onlineplayers) 
    dbManager:closeConnection()


    for i, v in ipairs(players) do
        utils.sendTable(id,"NKinsertPlayers", v)
    end

    MP.TriggerClientEvent(id, "NKgetPlayers", "") 

end

--- send one player to client
---@param id integer
---@param dbManager DatabaseManager
---@param permManager PermissionsHandler
---@param beammpid integer
function utils.sendPlayer(id, dbManager, permManager, beammpid)
    dbManager:openConnection()
    local player = dbManager:getUserWithRoles(beammpid)
    dbManager:closeConnection()
    local userInfos = {}
    userInfos.self_action_perm = {}
    local actions =  permManager:getActions(beammpid)
    for _, action in ipairs(actions) do
        table.insert(userInfos.self_action_perm, action.actionName) --need to fix every that
    end
    utils.sendTable(id, "NKgetUserInfos", userInfos) --update actions
    utils.sendTable(id, "NKinsertPlayers", player)
    MP.TriggerClientEvent(id, "NKgetPlayers", "") 
end

--- send every roles to client
---@param id integer
---@param event_name string
---@param dbManager DatabaseManager
function utils.sendRoles(id, event_name, dbManager)
    dbManager:openConnection()
    local roles = dbManager:getAllEntry(Roles, {})
    dbManager:closeConnection()

    local rolesfinal = {}
    for i, v in pairs(roles) do
        table.insert(rolesfinal, {permlvl = v.permlvl, roleName = v.roleName})
    end

    utils.sendTable(id, event_name, rolesfinal)
end

return utils