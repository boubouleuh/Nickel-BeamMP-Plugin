
local command = RegisterCommand("mute", {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "reason", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, playername, reason)
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
    local user = User.getOrCreate(beammpid, playername)
    
    if user:isMuted() or user:isTempMuted() then
        MessagesManager:SendMessage(sender_id, "moderation.alreadymuted", {Player = playername})
    else
        user:mute(reason)
        
        local target_id = Utils.GetPlayerId(playername)
        if target_id ~= -1 then
            MessagesManager:SendMessage(target_id, "moderation.muted", {Reason = reason})
        end
        MessagesManager:SendMessage(sender_id, "commands.mute.success", {Player = playername, Reason = reason})
    end

    return true
end