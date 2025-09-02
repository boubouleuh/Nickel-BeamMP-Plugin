return function(id)
    if ConfigManager.GetSetting("client").interface then
        local disconnectedPlayerName = MP.GetPlayerName(id)
        local disconnectedBeammpid = Utils.getPlayerBeamMPID(disconnectedPlayerName)
        
        if disconnectedBeammpid then
            local onlineplayers = MP.GetPlayers()
            for player_id, _ in pairs(onlineplayers) do
                if player_id ~= id then
                    MP.TriggerClientEventJson(player_id, "playerDisconnected", string.format('{"beammpid": %d}', disconnectedBeammpid))
                end
            end
        end
    end
end