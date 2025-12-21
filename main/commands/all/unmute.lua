
local command = RegisterCommand("unmute", {
    type = "user",
    args = {
        {name = "playername", type = "string"}
    }
})
--- command
function command.init(sender_id, sender_name, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.unmute.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)
    local user = User.getOrCreate(beammpid, playername)
    
    if user:isMuted() or user:isTempMuted() then
        user:unmute()
        MessagesManager:SendMessage(sender_id, "commands.unmute.success", {Player = playername})
    else
        MessagesManager:SendMessage(sender_id, "moderation.not_muted", {Player = playername})
    end

    return true
end
