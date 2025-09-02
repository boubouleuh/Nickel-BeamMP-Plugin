
local command = {
    type="global",
    args = {
        {name = "message", type = "string"}
    }
}
--- command
function command.init(sender_id, sender_name, _, message)
    if message == nil then
        MessagesManager:SendMessage(sender_id, "commands.broadcast.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    MessagesManager:SendMessage(-1, message)
  
    return true
end

RegisterNickelCommand("broadcast", command)