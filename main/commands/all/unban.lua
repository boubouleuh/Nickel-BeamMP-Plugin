

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"},
    }
}

--- command
function command.init(sender_id, sender_name, _, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.unban.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)
    local unbanned = false

    DatabaseManager:withConnection(function()
        local banStatus = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "isbanned"}})
        local tempBanStatus = DatabaseManager:getEntry(UserStatus, {{"beamMPID", beammpid}, {"statusType", "istempbanned"}})
        
        if banStatus then
            DatabaseManager:delete(banStatus)
            unbanned = true
        end
        
        if tempBanStatus then
            DatabaseManager:delete(tempBanStatus)
            unbanned = true
        end
        
        local userIps = DatabaseManager:getEntries(UserIp, {{"beammpid", beammpid}, {"is_banned", true}})
        local ipCount = 0
        
        for _, userIp in ipairs(userIps) do
            userIp.is_banned = false
            DatabaseManager:save(userIp)
            ipCount = ipCount + 1
        end
        
        if unbanned then
            MessagesManager:SendMessage(sender_id, "commands.unban.success", {Player = playername})
        elseif ipCount == 0 then
            MessagesManager:SendMessage(sender_id, "moderation.not_banned", {Player = playername})
        end
        
        if ipCount > 0 then
            MessagesManager:SendMessage(sender_id, "commands.unban.unbanip.success", {Count = ipCount, Player = playername})
        end
    end)

    return true
end

RegisterNickelCommand("unban", command)