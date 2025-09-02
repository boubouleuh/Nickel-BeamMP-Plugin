

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
        MessagesManager:SendMessage(sender_id, "commands.mute.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
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
        local existingMute = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "ismuted"}})
        local existingTempMute = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "istempmuted"}})
        
        if existingMute or existingTempMute then
            MessagesManager:SendMessage(sender_id, "moderation.alreadymuted", {Player = playername})
        else
            local userStatus = UserStatus.new(-1, beammpid, "ismuted", reason)
            DatabaseManager:save(userStatus)
            
            local target_id = Utils.GetPlayerId(playername)
            if target_id ~= -1 then
                MessagesManager:SendMessage(target_id, "moderation.muted", {Reason = reason})
            end
            MessagesManager:SendMessage(sender_id, "commands.mute.success", {Player = playername, Reason = reason})
        end
    end)

    return true
end

RegisterNickelCommand("mute", command)