
return Event(function(id)
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager.clear(beammpid)
    end

end):If(function(id) return not MP.IsPlayerGuest(id) end)