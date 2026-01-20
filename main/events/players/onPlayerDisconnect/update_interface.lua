return Event(function(id)
    local playerName = MP.GetPlayerName(id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    
    if beammpid then
        local onlineplayers = MP.GetPlayers()
        for player_id, _ in pairs(onlineplayers) do
            if player_id ~= id then
                MP.TriggerClientEventJson(player_id, "playerDisconnected", { beammpid = beammpid })
            end
        end
    end
end):Require(InterfaceChecker.isInstalled)