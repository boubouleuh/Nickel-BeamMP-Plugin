

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
    
        SetTimeout(50, function() InterfaceUtils.sendTable(id, "NKgetServerInfos", serverInfos) end)
        SetTimeout(50, function() InterfaceUtils.resetUserInfos(id) end)
        SetTimeout(50, function() InterfaceUtils.sendRoles(id, "NKgetRoles") end)
        SetTimeout(50, function() InterfaceUtils.sendUserCommands(id) end)
        SetTimeout(50, function() InterfaceUtils.sendGlobalCommands(id) end)
    end

    SetTimeout(50, function() InterfaceUtils.sendPlayers(id, offset) end)

    MP.TriggerLocalEvent("syncEnvironment", id, Util.JsonEncode(ConfigManager.GetSetting("client").environment), true)
    MP.TriggerLocalEvent("syncInterfaceValues", id, Util.JsonEncode(ConfigManager.GetSetting("client").interfaceValues), nil, true)

end