
return function(id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager:setPlayerData(beammpid, "synced", true)
    end
end