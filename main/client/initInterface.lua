
local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")
local Roles = require("objects.Role")
local interface = {}
local Users = require("objects.User")
local online = require "main.online"
--- initialize the interface for a given player
---@param id integer
---@param managers managers
function interface.init(id, managers, offset)

    local limit = 50

    print(offset)
    offset = tonumber(offset)
    if offset == nil then
        offset = 0
    end

    local playername = MP.GetPlayerName(id)
    local beammpid = utils.getPlayerBeamMPID(playername)

    local major, minor, patch = MP.GetServerVersion()
    -- managers.dbManager:openConnection()
    -- local players = managers.dbManager:getAllEntry(Users, {})
    -- managers.dbManager:closeConnection()

    managers.dbManager:openConnection()
    local roles = managers.dbManager:getAllEntry(Roles, {})
    managers.dbManager:closeConnection()
    local data = {}
    managers.dbManager:openConnection()
    local onlineplayers = MP.GetPlayers()
    data.players = managers.dbManager:getUsersDynamically(20, offset, onlineplayers) 
    managers.dbManager:closeConnection()

    print(data.players)
    data.roles = {}

    data.ip =  online.getServerIP()
    data.port = utils.getBeamMPConfig().General.Port
    data.server_version = major .. "." .. minor .. "." .. patch


    for i, v in pairs(roles) do
        table.insert(data.roles, {permlvl = v.permlvl, roleName = v.roleName})
    end


    interfaceUtils.sendTable(id, "getServerInfos", data)

end

return interface