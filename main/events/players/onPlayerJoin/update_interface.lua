return Event(function(id)
    local playerName = MP.GetPlayerName(id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    
    if beammpid then
        local onlineplayers = MP.GetPlayers()
        for player_id, _ in pairs(onlineplayers) do
            InterfaceUtils.sendPlayer(player_id, beammpid)
        end
    end

end):Require(InterfaceChecker.isInstalled)