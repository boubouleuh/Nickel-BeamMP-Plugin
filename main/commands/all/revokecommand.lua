
local command = RegisterCommand("revokecommand", {
    args = {
        {name = "commandName", type = "string"},
        {name = "rolename", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, commandName, rolename)
    if commandName == nil or rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.revokecommand.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    if sender_id ~= -2 then
        local senderBeammpid = Utils.getPlayerBeamMPID(sender_name)
        local senderUser = User.getOrCreate(senderBeammpid, sender_name)
        
        if not senderUser:canManageRole(rolename) then
            MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
            return false
        end
    end

    local role = RoleRepository.findByName(rolename)
    if not role then
        MessagesManager:SendMessage(sender_id, "commands.revokecommand.role_not_found", {Role = rolename})
        return false
    end
    
    local cmd = CommandRepository.findByName(commandName)
    if not cmd then
        MessagesManager:SendMessage(sender_id, "commands.revokecommand.command_not_found", {Command = commandName})
        return false
    end
    
    local existingRoleCommand = RoleCommandRepository.findByRoleAndCommand(role.roleID, cmd.commandID)
    if not existingRoleCommand or #existingRoleCommand == 0 then
        MessagesManager:SendMessage(sender_id, "commands.revokecommand.does_not_have_command", {Role = rolename, Command = commandName})
        return false
    end
    
    local code = RoleCommandRepository.delete(existingRoleCommand[1])
    MessagesManager:SendMessage(sender_id, "database.code." .. code)
    
    return true
end


