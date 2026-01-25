local command = RegisterCommand("deleterole", {
    args = {
        {name = "rolename", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, rolename)
    if rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.deleterole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end
    
    local capitalizedRolename = Utils.capitalize(rolename)

    DatabaseManager:withConnection(function()
        local role = DatabaseManager:getEntry(Role, "roleName", capitalizedRolename)
        if role then
            DatabaseManager:deleteObject(Role, {{"roleName", capitalizedRolename}})
            MessagesManager:SendMessage(sender_id, "commands.deleterole.success", {Role = capitalizedRolename})
            
        else
            local role2 = DatabaseManager:getEntry(Role, "roleName", rolename)
            if role2 then
                DatabaseManager:deleteObject(Role, {{"roleName", rolename}})
                MessagesManager:SendMessage(sender_id, "commands.deleterole.success", {Role = rolename})
            else
                MessagesManager:SendMessage(sender_id, "commands.deleterole.not_found", {Role = capitalizedRolename})
            end
        end
    end)
    
    return true
end