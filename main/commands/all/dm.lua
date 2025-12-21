
local command = RegisterCommand("dm", {
    type = "user",
    args = {
        {name = "target_name", type = "string"},
        {name = "message", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, target_name, message)
    if target_name == nil or message == nil then
        MessagesManager:SendMessage(sender_id, "commands.dm.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    local target_id = Utils.GetPlayerId(target_name)
    if target_id ~= -1 then
        if sender_id ~= target_id then
            MessagesManager:SendMessage(sender_id, "commands.dm.to", {Player = target_name, Message = message})
            MessagesManager:SendMessage(target_id, "commands.dm.from", {Player = sender_name, Message = message})
        else
            MessagesManager:SendMessage(sender_id, "commands.dm.cant_dm_yourself")
        end
    else
        MessagesManager:SendMessage(sender_id, "player.not_found", {Player = target_name})
    end

    return true
end