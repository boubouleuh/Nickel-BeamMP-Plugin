

local command = {
    args = {
        {name = "addORremove", type = "string"},
        {name = "playername", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, addORremove, playername)
    if playername == nil or not Utils.element_exist_in_table(addORremove, {"add", "remove"}) then
        MessagesManager:SendMessage(sender_id, "commands.whitelist.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if MP.IsPlayerGuest(Utils.GetPlayerId(playername)) then
        MessagesManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    
    local beammpid = Utils.getPlayerBeamMPID(playername)
    if not beammpid then
        MessagesManager:SendMessage(sender_id, "player.not_found", {Player = playername})
        return false
    end

    local user = User.getOrCreate(beammpid, playername)

    if addORremove == "add" then
        user:setWhitelisted(true)
        MessagesManager:SendMessage(sender_id, "commands.whitelist.add.success", {Player = playername})
    elseif addORremove == "remove" then
        user:setWhitelisted(false)
        MessagesManager:SendMessage(sender_id, "commands.whitelist.remove.success", {Player = playername})
    end

    return true
end

RegisterNickelCommand("whitelist", command)