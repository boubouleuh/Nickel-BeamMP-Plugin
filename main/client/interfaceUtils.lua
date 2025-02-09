local Roles = require("objects.Role")
local usersService = require("database.services.UsersService")
local misc = require("utils.misc")
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
---@param permManager PermissionsHandler
---@
function utils.sendPlayers(receiver_id, offset, dbManager, permManager)


    if receiver_id < 0 then
        error("Error in sendPlayer: receiver_id is negative, if you try to send to all players, please loop into every players manually to call this function")
    end

    dbManager:openConnection()
    local onlineplayers = MP.GetPlayers()
    local players = dbManager:getUsersDynamically(150, offset, onlineplayers, permManager) 
    dbManager:closeConnection()


    

    for i, v in ipairs(players) do
        if not permManager:hasPermissionForAction(misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)), "seeAdvancedUserInfos") then
            v.ips = {}
        end
        utils.sendTable(receiver_id,"NKinsertPlayers", v)
    end

    utils.resetUserInfos(receiver_id, permManager)

    MP.TriggerClientEvent(receiver_id, "NKgetPlayers", "") 

end



function utils.resetUserInfos(receiver_id, permManager)
    local userInfos = {}
    userInfos.self_action_perm = {}
    local actions = permManager:getActions(misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)))
    for _, action in ipairs(actions) do
        table.insert(userInfos.self_action_perm, action.actionName)
    end
    print(receiver_id, userInfos)
    utils.sendTable(receiver_id, "NKgetUserInfos", userInfos)
end

function utils.resetAllUserInfos(permManager)
    local onlineplayers = MP.GetPlayers()
    for i, v in ipairs(onlineplayers) do
        utils.resetUserInfos(i, permManager)
    end
end

function utils.sendUserCommands(receiver_id, permManager)
    local beammpid = misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id))
    local commands = permManager:getCommands(beammpid)
    local userCommands = {}
    for i, v in ipairs(commands) do
        local success, module = pcall(require, "main.commands.all." .. v.commandName)
        --if it exist then its a inbuilt command
        if success then
            local command = module
            command.init = nil --prevent warn messages
            if command.type then
                if command.type == "user" then
                    userCommands[v.commandName] = command
                end
            end
        else
            local success, module = require("extensions.commands." .. v.commandName)
            local command = module
            command.init = nil --prevent warn messages
            if command.type then
                if command.type == "user" then
                    userCommands[v.commandName] = command
                end
            end
        end --if not then its an extension command
    end
    utils.sendTable(receiver_id, "NKgetUserCommands", userCommands)
end

--- send one player to client
---@param id integer
---@param dbManager DatabaseManager
---@param permManager PermissionsHandler
---@param beammpid integer
function utils.sendPlayer(receiver_id, dbManager, permManager, beammpid)

    if receiver_id < 0 then
        error("Error in sendPlayer: receiver_id is negative, if you try to send to all players, please loop into every players manually to call this function")
    end

    dbManager:openConnection()
    local player = dbManager:getUserWithRoles(beammpid, permManager)
    dbManager:closeConnection()

    if not permManager:hasPermissionForAction(misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)), "seeAdvancedUserInfos") then
        player.ips = {}
    end
    utils.resetUserInfos(receiver_id, permManager)
    utils.sendTable(receiver_id, "NKinsertPlayers", player)
    MP.TriggerClientEvent(receiver_id, "NKgetPlayers", "") 
end

--- send every roles to client
---@param id integer
---@param event_name string
---@param dbManager DatabaseManager
function utils.sendRoles(id, event_name, dbManager)
    dbManager:openConnection()
    local roles = dbManager:getAllEntry(Roles)
    dbManager:closeConnection()

    local rolesfinal = {}
    for i, v in pairs(roles) do
        table.insert(rolesfinal, {permlvl = v.permlvl, roleName = v.roleName})
    end

    utils.sendTable(id, event_name, rolesfinal)
end

return utils