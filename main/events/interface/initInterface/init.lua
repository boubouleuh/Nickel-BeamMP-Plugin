local lastCallTime = {}
local cooldown = 2

return function (id, offset)
    local currentTime = os.time()
    if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
        lastCallTime[id] = currentTime
        
        local playerName = MP.GetPlayerName(id)
        local beammpid = Utils.getPlayerBeamMPID(playerName)
        
        if beammpid then
            local playerData = Utils.playerDataToJson(beammpid)
            if playerData then
                MP.TriggerClientEventJson(id, "initInterface", playerData)
            end
            
            local clientConfig = ConfigManager.GetSetting("client")
            if clientConfig and clientConfig.interfaceValues then
                MP.TriggerClientEventJson(id, "getInterfaceValues", clientConfig.interfaceValues)
            end
        end
    end
end

