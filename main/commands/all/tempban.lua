
local command = RegisterCommand("tempban", {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "time", type = "string"},
        {name = "reason", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, playername, time, reason)
    if playername == nil or time == nil then
        MessagesManager:SendMessage(sender_id, "commands.tempban.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
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
    local user = User.getOrCreate(beammpid, playername)
    
    if user:isBanned() or user:isTempBanned() then
        MessagesManager:SendMessage(sender_id, "moderation.alreadybanned", {Player = playername})
    else
        user:tempBan(reason, timestamp)
        
        local target_id = Utils.GetPlayerId(playername)
        if target_id ~= -1 then
            MP.DropPlayer(target_id, reason .. " " .. MessagesManager:GetMessage(sender_id, "moderation.tempbanned", {Reason = reason, Date = end_date}))
        end
        MessagesManager:SendMessage(sender_id, "commands.tempban.success", {Player = playername, Reason = reason, Date = end_date})
    end
    
    return true
end