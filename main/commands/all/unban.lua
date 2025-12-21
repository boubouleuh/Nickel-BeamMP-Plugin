
local command = RegisterCommand("unban", {
    type = "user",
    args = {
        {name = "playername", type = "string"},
    }
})
--- command
function command.init(sender_id, sender_name, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.unban.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)
    local user = User.getOrCreate(beammpid, playername)
    
    local wasBanned = user:isBanned() or user:isTempBanned()
    
    if wasBanned then
        user:unban()
        MessagesManager:SendMessage(sender_id, "commands.unban.success", {Player = playername})
    end
    
    -- Also unban IPs
    local ipCount = user:unbanAllIps()
    
    if not wasBanned and ipCount == 0 then
        MessagesManager:SendMessage(sender_id, "moderation.not_banned", {Player = playername})
    elseif ipCount > 0 then
        MessagesManager:SendMessage(sender_id, "commands.unban.unbanip.success", {Count = ipCount, Player = playername})
    end

    return true
end