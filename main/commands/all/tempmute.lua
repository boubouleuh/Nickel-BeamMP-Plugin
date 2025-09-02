

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "time", type = "string"},
        {name = "reason", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, playername, time, reason)
    if playername == nil or time == nil then
        MessagesManager:SendMessage(sender_id, "commands.tempmute.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    elseif reason == nil then
        reason = MessagesManager:GetMessage(sender_id, "moderation.default_reason")
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    
    local timestamp = os.time() + Utils.timeConverter(time)
    local end_date = os.date("%d/%m/%Y %H:%M:%S", timestamp)

    local beammpid = Utils.getPlayerBeamMPID(playername)

    DatabaseManager:withConnection(function()
        local existingMute = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "ismuted"}})
        local existingTempMute = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "istempmuted"}})
        
        if existingMute or existingTempMute then
            MessagesManager:SendMessage(sender_id, "moderation.alreadymuted", {Player = playername})
        else
            local userStatus = UserStatus.new(-1, beammpid, "istempmuted", reason, timestamp)
            DatabaseManager:save(userStatus)
            
            local target_id = Utils.GetPlayerId(playername)

            if target_id ~= -1 then
                MessagesManager:SendMessage(target_id, "moderation.tempmuted", {Reason = reason, Date = end_date})
            end
            MessagesManager:SendMessage(sender_id, "commands.tempmute.success", {Player = playername, Reason = reason, Date = end_date})
        end
    end)

    return true
end

RegisterNickelCommand("tempmute", command)