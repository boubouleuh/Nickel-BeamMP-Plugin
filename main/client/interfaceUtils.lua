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

    local seeAdvancedUserInfos = permManager:hasPermissionForAction(misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id)), "seeAdvancedUserInfos")
    dbManager:openConnection()
    local onlineplayers = MP.GetPlayers()
    local players = dbManager:getUsersDynamically(-1, 0, onlineplayers, seeAdvancedUserInfos)
    dbManager:closeConnection()

    local maxPacketSize = 19500 -- 19.5 KB
    local currentPacket = {}
    local currentSize = 0


    for i, v in ipairs(players) do

        local playerData = Util.JsonEncode(v) 
        local playerSize = #playerData

        if currentSize + playerSize > maxPacketSize then
            utils.sendTable(receiver_id, "NKinsertPlayers", currentPacket)
            currentPacket = {}
            currentSize = 0
        end
        table.insert(currentPacket, v)
        currentSize = currentSize + playerSize
    end

    if #currentPacket > 0 then
        utils.sendTable(receiver_id,"NKinsertPlayers", currentPacket)
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
    utils.sendTable(receiver_id, "NKgetUserInfos", userInfos)
end

function utils.resetAllUserInfos(permManager)
    local onlineplayers = MP.GetPlayers()
    for i, v in ipairs(onlineplayers) do
        utils.resetUserInfos(i, permManager)
    end
end

function utils.sendUserCommands(receiver_id, permManager, commandsHandler)
    local beammpid = misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id))
    local commands = permManager:getCommands(beammpid)
    local userCommands = {}
    local commandCache = commandsHandler:GetCommands()
    for i, v in ipairs(commands) do

        local command = commandCache[v.commandName]
        if command then
            if command.type and command.type == "user" then
                userCommands[v.commandName] = {
                    args = command.args or {},
                    type = command.type
                }
            end
        end
    end
    utils.sendTable(receiver_id, "NKgetUserCommands", userCommands)
end

function utils.sendGlobalCommands(receiver_id, permManager, commandsHandler)
    local beammpid = misc.getPlayerBeamMPID(MP.GetPlayerName(receiver_id))
    local commands = permManager:getCommands(beammpid)
    local globalCommands = {}
    local commandCache = commandsHandler:GetCommands()
    for i, v in ipairs(commands) do
        local command = commandCache[v.commandName]
        if command then
            if command.type and command.type == "global" then
                globalCommands[v.commandName] = {
                    args = command.args or {},
                    type = command.type,
                    extension = command.extension
                }
            end
        end
    end
    utils.sendTable(receiver_id, "NKgetGlobalCommands", globalCommands)
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