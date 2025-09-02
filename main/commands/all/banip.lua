

local command = {
    type = "user",
    args = {
        {name = "playername", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.banip.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)

    DatabaseManager:withConnection(function()
        local userIps = DatabaseManager:getEntries(UserIp, {{"beammpid", beammpid}})
        local count = 0
        
        for _, userIp in ipairs(userIps) do
            local existingBan = DatabaseManager:getEntry(UserIp, {{"ip", userIp.ip}, {"is_banned", true}})
            if not existingBan then
                -- Marquer cette IP comme bannie
                userIp.is_banned = true
                DatabaseManager:save(userIp)
                count = count + 1
            end
        end

        if count > 0 then
            MessagesManager:SendMessage(sender_id, "commands.banip.success", {Count = count, Player = playername})
        else
            MessagesManager:SendMessage(sender_id, "commands.banip.no_registered", {Player = playername})
        end
    end)

    return true
end

RegisterNickelCommand("banip", command)