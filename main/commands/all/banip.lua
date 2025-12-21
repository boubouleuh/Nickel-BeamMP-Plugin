
local command = RegisterCommand("banip", {
    type = "user",
    args = {
        {name = "playername", type = "string"}
    }
})

function command.init(sender_id, sender_name, playername)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.banip.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(playername)
    local user = User.getOrCreate(beammpid, playername)

    local count = user:banAllIps()
    
    local target_id = Utils.GetPlayerId(playername)

    if target_id ~= -1 then
        MP.DropPlayer(target_id, MessagesManager:GetMessage(sender_id, "moderation.banned_ip"))
    end
    MessagesManager:SendMessage(sender_id, "commands.banip.success", {Count = count, Player = playername})



    return true
end