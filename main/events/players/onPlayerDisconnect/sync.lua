
return function(id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager.clear(beammpid)
    end
end