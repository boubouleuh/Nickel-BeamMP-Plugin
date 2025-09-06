

local command = {
    type = "global",
    args = {}
}

--- command
function command.init(sender_id, sender_name)
    MessagesManager:SendMessage(sender_id, "commands.importLegacyData.not_available")
    return false
end

RegisterNickelCommand("importLegacyData", command)