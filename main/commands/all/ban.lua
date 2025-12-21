local command = RegisterCommand("ban", {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "reason", type = "string"}
    }
})

function command.init(sender_id, sender_name, playername, reason)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.ban.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end
    if reason == nil then
        reason = MessagesManager:GetMessage(sender_id, "moderation.default_reason")
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)
    local user = User.getOrCreate(beammpid, playername)

    if user:isBanned() or user:isTempBanned() then
        MessagesManager:SendMessage(sender_id, "moderation.alreadybanned", {Player = playername})
    else
        local result = user:ban(reason)
        
        local target_id = Utils.GetPlayerId(playername)
        if target_id ~= -1 then
            MP.DropPlayer(target_id, MessagesManager:GetMessage(sender_id, "moderation.banned", {Reason = reason}))
        end
        
        MessagesManager:SendMessage(sender_id, "commands.ban.success", {Player = playername, Reason = reason})
        MessagesManager:SendMessage(sender_id, string.format("database.code.%s", result))
    end

    return true
end