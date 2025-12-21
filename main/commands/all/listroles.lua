

local command = RegisterCommand("listroles", {
    type = "global",
    args = {}
})

--- command
function command.init(sender_id, sender_name)
    DatabaseManager:withConnection(function()
        local roles = DatabaseManager:getAllEntry(Role)
        table.sort(roles, function(a, b) return a.permlvl > b.permlvl end)
        for _, role in pairs(roles) do
            MessagesManager:SendMessage(sender_id, role.roleName .. " | " .. role.permlvl)
        end
    end)
    return true
end