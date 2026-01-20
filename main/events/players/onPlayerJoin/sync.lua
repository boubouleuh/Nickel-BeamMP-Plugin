
return Event(function(id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager.set(beammpid, "synced", true)
    end
end)