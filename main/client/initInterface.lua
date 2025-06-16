
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
    utils.nkprint("offset is " .. offset,"debug")
    utils.nkprint("id is " .. id,"debug")
    if offset == 0 then
        local major, minor, patch = MP.GetServerVersion()


        local serverInfos = {}
        serverInfos.ip =  online.getServerIP()
        serverInfos.port = utils.getBeamMPConfig().General.Port
        serverInfos.server_version = major .. "." .. minor .. "." .. patch
        serverInfos.server_name = utils.getBeamMPConfig().General.Name
        

        interfaceUtils.sendTable(id, "NKgetServerInfos", serverInfos)

        interfaceUtils.resetUserInfos(id, managers.permManager)
        
        interfaceUtils.sendRoles(id, "NKgetRoles", managers.dbManager)
        interfaceUtils.sendUserCommands(id, managers.permManager, managers.cmdManager)  -- make event 'on perm change' and things to make updating, do the same for everything else
        interfaceUtils.sendGlobalCommands(id, managers.permManager ,managers.cmdManager)
    end
 

    -- utils.RunAsync(interfaceUtils.sendPlayers, 50, id, offset, managers.dbManager, managers.permManager)
    interfaceUtils.sendPlayers(id, offset, managers.dbManager, managers.permManager)
    MP.TriggerLocalEvent("SyncEnvironment", id, Util.JsonEncode(managers.cfgManager:GetSetting("client").environment), true)
    MP.TriggerLocalEvent("SyncInterfaceValues", id, Util.JsonEncode(managers.cfgManager:GetSetting("client").interfaceValues), true)

end

return interface