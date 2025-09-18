

InterfaceManager = {}

--- initialize the interface for a given player
---@param id integer
---@param offset integer|nil
function InterfaceManager.init(id, offset)

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
        
        Utils.RunAsync(InterfaceUtils.sendTable, 50, id, "NKgetServerInfos", serverInfos)
        Utils.RunAsync(InterfaceUtils.resetUserInfos, 50, id)
        Utils.RunAsync(InterfaceUtils.sendRoles, 50, id, "NKgetRoles")
        Utils.RunAsync(InterfaceUtils.sendUserCommands, 50, id)
        Utils.RunAsync(InterfaceUtils.sendGlobalCommands, 50, id)
    end

    Utils.RunAsync(InterfaceUtils.sendPlayers, 50, id, offset)
    
    MP.TriggerLocalEvent("syncEnvironment", id, Util.JsonEncode(ConfigManager.GetSetting("client").environment), nil, true)
    MP.TriggerLocalEvent("syncInterfaceValues", id, Util.JsonEncode(ConfigManager.GetSetting("client").interfaceValues), nil, true)

end