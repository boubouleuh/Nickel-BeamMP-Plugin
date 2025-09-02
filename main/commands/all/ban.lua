

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "reason", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, playername, reason)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.ban.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    elseif reason == nil then
        reason = MessagesManager:GetMessage(sender_id, "moderation.default_reason")
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    
    local beammpid = Utils.getPlayerBeamMPID(playername)

    DatabaseManager:withConnection(function()
        local existingStatus = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "isbanned"}})
        local existingTempBan = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "istempbanned"}})
        
        if existingStatus or existingTempBan then
            MessagesManager:SendMessage(sender_id, "moderation.alreadybanned", {Player = playername})
        else
            local userStatus = UserStatus.new(-1, beammpid, "isbanned", reason)
            DatabaseManager:save(userStatus)
            
            local target_id = Utils.GetPlayerId(playername)

            if target_id ~= -1 then
                MP.DropPlayer(target_id, MessagesManager:GetMessage(sender_id, "moderation.banned", {Reason = reason}))
            end
            MessagesManager:SendMessage(sender_id, "commands.ban.success", {Player = playername, Reason = reason})
        end
    end)
   
    return true
end

RegisterNickelCommand("ban", command)