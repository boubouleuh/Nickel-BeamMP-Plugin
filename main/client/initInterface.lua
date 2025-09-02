

local interfaceUtils = require("main.client.interfaceUtils")
local interface = {}

--- initialize the interface for a given player
---@param id integer
---@param managers managers
function interface.init(id, managers, offset)

    if offset == nil then
        offset = 0
    else
        offset = tonumber(offset)
    end
    
    Utils.nkprint("offset is " .. offset, "debug")
    Utils.nkprint("id is " .. id, "debug")
    
    if offset == 0 then
        local major, minor, patch = MP.GetServerVersion()

        local serverInfos = {}
        serverInfos.ip = Online.getServerIP()
        serverInfos.port = Utils.getBeamMPConfig().General.Port
        serverInfos.server_version = major .. "." .. minor .. "." .. patch
        serverInfos.server_name = Utils.getBeamMPConfig().General.Name
        
        Utils.RunAsync(interfaceUtils.sendTable, 50, id, "NKgetServerInfos", serverInfos)
        Utils.RunAsync(interfaceUtils.resetUserInfos, 50, id, PermissionsManager)
        Utils.RunAsync(interfaceUtils.sendRoles, 50, id, "NKgetRoles", DatabaseManager)
        Utils.RunAsync(interfaceUtils.sendUserCommands, 50, id, PermissionsManager, CommandsManager)
        Utils.RunAsync(interfaceUtils.sendGlobalCommands, 50, id, PermissionsManager, CommandsManager)
    end

    Utils.RunAsync(interfaceUtils.sendPlayers, 50, id, offset, DatabaseManager, PermissionsManager, ConfigManager)
    
    MP.TriggerLocalEvent("syncEnvironment", id, Util.JsonEncode(Settings.GetSetting("client").environment), managers, true)
    MP.TriggerLocalEvent("syncInterfaceValues", id, Util.JsonEncode(Settings.GetSetting("client").interfaceValues), managers, true)

end

return interface