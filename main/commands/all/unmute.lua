

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.unmute.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)

    DatabaseManager:withConnection(function()
        local muteStatus = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "ismuted"}})
        local tempMuteStatus = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "istempmuted"}})
        
        if muteStatus or tempMuteStatus then
            if muteStatus then
                DatabaseManager:delete(muteStatus)
            end
            if tempMuteStatus then
                DatabaseManager:delete(tempMuteStatus)
            end
            MessagesManager:SendMessage(sender_id, "commands.unmute.success", {Player = playername})
        else
            MessagesManager:SendMessage(sender_id, "moderation.not_muted", {Player = playername})
        end
    end)

    return true
end

RegisterNickelCommand("unmute", command)