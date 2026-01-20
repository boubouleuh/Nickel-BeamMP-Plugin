
return Event(function()
    local clientConfig = ConfigManager.GetSetting("client")
    
    if clientConfig and clientConfig.interfaceValues then
        MP.TriggerClientEventJson(-1, "getInterfaceValues", clientConfig.interfaceValues)
    end

    if clientConfig and clientConfig.environment then
        MP.TriggerClientEventJson(-1, "receiveEnvironment", clientConfig.environment)
    end
end):Every(10000)

