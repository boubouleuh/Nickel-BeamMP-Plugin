
local command = {
    type = "user",
    args = {
        {name = "rolename", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, rolename)
    if rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.deleterole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    DatabaseManager:withConnection(function()
        local role = DatabaseManager:getEntry(Role, {{"roleName", rolename}})
        if role then
            DatabaseManager:delete(role)
            MessagesManager:SendMessage(sender_id, "commands.deleterole.success", {Role = rolename})
            
            local onlineplayers = MP.GetPlayers()
            for id, player in pairs(onlineplayers) do
            end
        else
            MessagesManager:SendMessage(sender_id, "commands.deleterole.not_found", {Role = rolename})
        end
    end)
    
    return true
end

RegisterNickelCommand("deleterole", command)