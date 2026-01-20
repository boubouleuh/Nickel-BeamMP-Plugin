

return Event(function(id, environment, force)
    local client_env = Util.JsonDecode(environment)

    if force == nil then
        force = false
    end
    if client_env == nil then
        Utils.nkprint("CLIENT ENVIRONMENT IS NIL", "error")
        return
    end
    local playerName = MP.GetPlayerName(id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    local clientConfig = ConfigManager.GetSetting("client")
    local server_env = clientConfig and clientConfig.environment
    local user = User.getOrCreate(beammpid, playerName)
    if not Utils.deepCompare(client_env, server_env) or force then

        if not user:hasPermissionForAction("editEnvironment") then
            MP.TriggerClientEventJson(id, "receiveEnvironment", server_env)
            return
        end
    
        ConfigManager.SetSetting("client.environment", client_env)
        MP.TriggerClientEventJson(-1, "receiveEnvironment", client_env)
    end
end)

