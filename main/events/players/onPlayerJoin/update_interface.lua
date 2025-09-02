return function(id)
    if ConfigManager.GetSetting("client").interface then
        local playerName = MP.GetPlayerName(id)
        local beammpid = Utils.getPlayerBeamMPID(playerName)
        
        if beammpid then
            local onlineplayers = MP.GetPlayers()
            for player_id, _ in pairs(onlineplayers) do
                MP.TriggerClientEventJson(player_id, "updatePlayerData", Utils.playerDataToJson(beammpid))
            end
        end
    end
end