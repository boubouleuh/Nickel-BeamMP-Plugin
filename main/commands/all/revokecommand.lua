

local command = {
    type = "user",
    args = {
        {name = "commandName", type = "string"},
        {name = "rolename", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, commandName, rolename)
    if commandName == nil or rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.revokecommand.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    if sender_id ~= -2 then
        local senderBeammpid = Utils.getPlayerBeamMPID(sender_name)
        if not PermissionsManager:canManageRole(senderBeammpid, rolename) then
            MessagesManager:SendMessage(sender_id, "commands.permissions.insufficient.manage_role", {Role = rolename})
            return false
        end
    end

    DatabaseManager:withConnection(function()
        local role = DatabaseManager:getEntry(Role, {{"roleName", rolename}})
        if not role then
            MessagesManager:SendMessage(sender_id, "commands.revokecommand.role_not_found", {Role = rolename})
            return
        end
        
        local cmd = DatabaseManager:getEntry(Command, {{"commandName", commandName}})
        if not cmd then
            MessagesManager:SendMessage(sender_id, "commands.revokecommand.command_not_found", {Command = commandName})
            return
        end
        
        local existingRoleCommand = DatabaseManager:getEntry(RoleCommand, {{"roleID", role.roleID}, {"commandID", cmd.commandID}})
        if not existingRoleCommand then
            MessagesManager:SendMessage(sender_id, "commands.revokecommand.does_not_have_command", {Role = rolename, Command = commandName})
        else
            DatabaseManager:delete(RoleCommand, {{"roleID", role.roleID}, {"commandID", cmd.commandID}})
            MessagesManager:SendMessage(sender_id, "commands.revokecommand.success", {Role = rolename, Command = commandName})
        end
    end)

    return true
end

RegisterNickelCommand("revokecommand", command)


