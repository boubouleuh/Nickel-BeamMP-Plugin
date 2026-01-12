return function(id)
    if InterfaceChecker.isInstalled then
        local playerName = MP.GetPlayerName(id)
        local beammpid = Utils.getPlayerBeamMPID(playerName)
        
        if beammpid then
            local onlineplayers = MP.GetPlayers()
            for player_id, _ in pairs(onlineplayers) do
                if player_id ~= id then
                    MP.TriggerClientEventJson(player_id, "playerDisconnected", string.format('{"beammpid": %d}', beammpid))
                end
            end
        end
    end
end