
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

    if offset == nil then
        offset = 0
    else
        offset = tonumber(offset)
    end

    if offset == 0 then
        local major, minor, patch = MP.GetServerVersion()


        local serverInfos = {}
        serverInfos.ip =  online.getServerIP()
        serverInfos.port = utils.getBeamMPConfig().General.Port
        serverInfos.server_version = major .. "." .. minor .. "." .. patch

        

        interfaceUtils.sendTable(id, "NKgetServerInfos", serverInfos)

        interfaceUtils.resetUserInfos(id, id, managers.permManager)

        interfaceUtils.sendRoles(id, "NKgetRoles", managers.dbManager)
    end
 

    interfaceUtils.sendPlayers(id, id, offset, managers.dbManager, managers.permManager)
    MP.TriggerLocalEvent("SyncEnvironment", id, Util.JsonEncode(managers.cfgManager:GetSetting("client")), true)
end

return interface