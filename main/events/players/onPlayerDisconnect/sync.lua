
return function(id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager:clearPlayerSession(beammpid)
    end
end