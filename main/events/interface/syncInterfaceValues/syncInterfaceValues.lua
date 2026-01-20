return Event(function(id, interfaceValues, force)
    local interfaceValues = Util.JsonDecode(interfaceValues)
    if force == nil then
        force = false
    end
    if interfaceValues == nil then
        Utils.nkprint("INTERFACE VALUES IS NIL", "error")
        return
    end
    
    local clientConfig = ConfigManager.GetSetting("client")
    local server_interface_values = clientConfig and clientConfig.interfaceValues

    if not Utils.deepCompare(interfaceValues, server_interface_values) or force then
        local playerName = MP.GetPlayerName(id)
        local beammpid = Utils.getPlayerBeamMPID(playerName)
        
        if not User.findByBeammpid(beammpid):hasPermissionForAction("editInterfaceSettings") then
            MP.TriggerClientEventJson(id, "getInterfaceValues", server_interface_values)
            return
        end

        ConfigManager.SetSetting("client.interfaceValues", interfaceValues)
        MP.TriggerClientEventJson(-1, "getInterfaceValues", interfaceValues)
    end
end)
