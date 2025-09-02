

local command = {
    type = "user",
    args = {
        {name = "actionName", type = "string"},
        {name = "rolename", type = "string"}
    }
}

--- command
function command.init(sender_id, sender_name, _, actionName, rolename)
    if actionName == nil or rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.revokeaction.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    DatabaseManager:withConnection(function()
        local role = DatabaseManager:getEntry(Role, {{"roleName", rolename}})
        if not role then
            MessagesManager:SendMessage(sender_id, "commands.revokeaction.role_not_found", {Role = rolename})
            return
        end
        
        local action = DatabaseManager:getEntry(Action, {{"actionName", actionName}})
        if not action then
            MessagesManager:SendMessage(sender_id, "commands.revokeaction.action_not_found", {Action = actionName})
            return
        end
        
        local existingRoleAction = DatabaseManager:getEntry(RoleAction, {{"roleID", role.roleID}, {"actionID", action.actionID}})
        if not existingRoleAction then
            MessagesManager:SendMessage(sender_id, "commands.revokeaction.does_not_have_action", {Role = rolename, Action = actionName})
        else
            DatabaseManager:delete(RoleAction, {{"roleID", role.roleID}, {"actionID", action.actionID}})
            MessagesManager:SendMessage(sender_id, "commands.revokeaction.success", {Role = rolename, Action = actionName})
        end
    end)

    return true
end

RegisterNickelCommand("revokeaction", command)


