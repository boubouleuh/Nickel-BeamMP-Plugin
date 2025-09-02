
return function(id)
    local playerName = MP.GetPlayerName(id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    
    if beammpid then
        local highestRole = PermissionsManager:GetHighestRole(beammpid)
        local roleName = highestRole and highestRole.roleName or "Guest"
        
        local joinMessage = ConfigManager.GetSetting("misc").join_message
        if joinMessage then
            MessagesManager:SendMessage(-1, joinMessage, {
                Role = roleName,
                Player = playerName
            })
        end
    end
end