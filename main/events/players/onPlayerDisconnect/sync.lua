
return function(id)
    if MP.isPlayerGuest(id) then
        return
    end
    local beammpid = Utils.getPlayerBeamMPID(MP.GetPlayerName(id))
    if beammpid then
        SessionManager.clear(beammpid)
    end
end