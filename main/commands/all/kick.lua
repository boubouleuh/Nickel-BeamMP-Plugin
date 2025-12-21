
local command = RegisterCommand("kick", {
    type = "user",
    args = {
        {name = "playername", type = "string"},
        {name = "reason", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, playername, reason)
    if playername == nil then
        MessagesManager:SendMessage(sender_id, "commands.kick.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    elseif reason == nil then
        reason = MessagesManager:GetMessage(sender_id, "moderation.default_reason")
    end

    local target_id = Utils.GetPlayerId(playername)

    if target_id ~= -1 then
        MP.DropPlayer(target_id, reason)
    end
    MessagesManager:SendMessage(sender_id, "commands.kick.success", {Player = playername, Reason = reason})

    return true
end