
return Event(function(id)
    local playerName = MP.GetPlayerName(id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    
    if beammpid then
        local highestRole = User.findByBeammpid(beammpid):getHighestRole()
        local roleName = highestRole and highestRole.roleName or "Guest"
        
        local joinMessage = ConfigManager.GetSetting("misc").join_message
        if joinMessage then
            MessagesManager:SendMessage(-1, joinMessage, {
                Role = roleName,
                Player = playerName
            })
        end
    end
end)