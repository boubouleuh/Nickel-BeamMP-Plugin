
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
        local userInfos = {}
        userInfos.self_action_perm = {}
        serverInfos.ip =  online.getServerIP()
        serverInfos.port = utils.getBeamMPConfig().General.Port
        serverInfos.server_version = major .. "." .. minor .. "." .. patch

        local actions = managers.permManager:getActions(utils.getPlayerBeamMPID(MP.GetPlayerName(id)))
        for _, action in ipairs(actions) do
            table.insert(userInfos.self_action_perm, action.actionName)
        end
        

        interfaceUtils.sendTable(id, "NKgetServerInfos", serverInfos)

        interfaceUtils.sendTable(id, "NKgetUserInfos", userInfos)

        interfaceUtils.sendRoles(id, "NKgetRoles", managers.dbManager)
    end
 

    interfaceUtils.sendPlayers(id, offset, managers.dbManager)
    MP.TriggerLocalEvent("SyncEnvironment", id, Util.JsonEncode(managers.cfgManager:GetSetting("client")), true)
end

return interface