

local command = {
    type = "user",
    args = {
        {name = "rolename", type = "string"},
        {name = "permlvl", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, rolename, permlvl)
    if rolename == nil or permlvl == nil then
        MessagesManager:SendMessage(sender_id, "commands.createrole.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    local permlvl_num = tonumber(permlvl)
    if not permlvl_num then
        MessagesManager:SendMessage(sender_id, "commands.createrole.invalid_permlvl")
        return false
    end

    DatabaseManager:withConnection(function()
        local existingRole = DatabaseManager:getEntry(Role, {{"roleName", rolename}})
        if existingRole then
            MessagesManager:SendMessage(sender_id, "commands.createrole.already_exists", {Role = rolename})
        else
            local newRole = Role.new(rolename, permlvl_num)
            DatabaseManager:save(newRole)
            MessagesManager:SendMessage(sender_id, "commands.createrole.success", {Role = rolename, PermLevel = permlvl})
        end
    end)
    
    return true
end

RegisterNickelCommand("createrole", command)