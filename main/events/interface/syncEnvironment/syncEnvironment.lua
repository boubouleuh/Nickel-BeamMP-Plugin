

return function(id, environment, force)
    local environment = Util.JsonDecode(environment)

    if force == nil then
        force = false
    end
    if environment == nil then
        Utils.nkprint("ENVIRONMENT IS NIL", "error")
        return
    end
    
    local clientConfig = ConfigManager.GetSetting("client")
    local server_env = clientConfig and clientConfig.environment

    if not Utils.deepCompare(environment, server_env) or force then
        local playerName = MP.GetPlayerName(id)
        local beammpid = Utils.getPlayerBeamMPID(playerName)
        
        if not User.findByBeammpid(beammpid):hasPermissionForAction("editEnvironment") then
            MP.TriggerClientEventJson(id, "receiveEnvironment", server_env)
            return
        end
    
        ConfigManager.SetSetting("client.environment", environment)
        MP.TriggerClientEventJson(-1, "receiveEnvironment", environment)
    end
end

