
return Event(function(player_id, player_name, message)
    local beammpid = Utils.getPlayerBeamMPID(player_name)
    if not beammpid then
        return CommandsManager:CreateCommand(player_id, message, true)
    end
    
    if StatusService.canPlayerSpeak(beammpid) then
        return CommandsManager:CreateCommand(player_id, message, true)
    end
    
    local muteReason = StatusService.getStatusReason(beammpid, "ismuted") or 
                      StatusService.getStatusReason(beammpid, "istempmuted")
    
    if muteReason and muteReason ~= "" then
        MP.SendChatMessage(player_id, "[MUTED] You are muted. Reason: " .. muteReason)
    else
        MP.SendChatMessage(player_id, "[MUTED] You are muted.")
    end
    
    return false
end)