
local command = RegisterCommand("whitelist", {
    type = "user",
    args = {
        {name = "addORremove", type = "string"},
        {name = "playername", type = "string"}
    }
})
--- command
function command.init(sender_id, sender_name, action, playername)
    if not Utils.element_exist_in_table(action, {"add", "remove", "clear"}) then
        MessagesManager:SendMessage(sender_id, "commands.whitelist.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    if action == "clear" then
        local users = UserRepository.findAllWhitelisted()
        local count = 0
        for _, user in pairs(users) do
            user:setWhitelisted(false)
            count = count + 1
        end
        MessagesManager:SendMessage(sender_id, "commands.whitelist.clear.success", {Count = count})
        return true
    end

    if not playername then
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

    if action == "add" then
        user:setWhitelisted(true)
        MessagesManager:SendMessage(sender_id, "commands.whitelist.add.success", {Player = playername})
    elseif action == "remove" then
        user:setWhitelisted(false)
        MessagesManager:SendMessage(sender_id, "commands.whitelist.remove.success", {Player = playername})
    end

    return true
end