local command = RegisterCommand("listactions", {
    type = "global",
    args = {}
})

--- command
function command.init(sender_id, sender_name)
    DatabaseManager:withConnection(function()
        local actions = DatabaseManager:getAllEntry(Action)
        
        if #actions == 0 then
            MessagesManager:SendMessage(sender_id, "commands.listactions.no_actions")
        else
            MessagesManager:SendMessage(sender_id, "commands.listactions.header")
            for _, action in pairs(actions) do
                MessagesManager:SendMessage(sender_id, action.actionName)
            end
        end
    end)
    
    return true
end