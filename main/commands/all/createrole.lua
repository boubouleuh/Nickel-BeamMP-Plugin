
local command = RegisterCommand("createrole", {
    args = {
        {name = "rolename", type = "string"},
        {name = "permlvl", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, rolename, permlvl)
    if rolename == nil or permlvl == nil then
        MessagesManager:SendMessage(sender_id, "commands.createrole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end
    
    rolename = Utils.capitalize(rolename)

    local permlvl_num = tonumber(permlvl)
    if not permlvl_num then
        MessagesManager:SendMessage(sender_id, "commands.createrole.invalid_permlvl")
        return false
    end

    DatabaseManager:withConnection(function()
        local existingRoles = DatabaseManager:getAllEntry(Role, {{"roleName", rolename}})
        if existingRoles and #existingRoles > 0 then
            MessagesManager:SendMessage(sender_id, "commands.createrole.already_exists", {Role = rolename})
        else
            local newRole = Role.new(rolename, permlvl_num, false)            
            local result = DatabaseManager:save(newRole, true)
            

            MessagesManager:SendMessage(sender_id, "database.code." .. result)
            
        end
    end)
    
    return true
end