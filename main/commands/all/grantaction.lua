

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
        MessagesManager:SendMessage(sender_id, "commands.grantaction.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
        return false
    end

    rolename = Utils.capitalize(rolename)

    DatabaseManager:withConnection(function()
        local role = DatabaseManager:getAllEntry(Role, {{"roleName", rolename}})
        if not role then
            MessagesManager:SendMessage(sender_id, "commands.grantaction.role_not_found", {Role = rolename})
            return
        end
        
        local action = DatabaseManager:getAllEntry(Action, {{"actionName", actionName}})
        if not action then
            MessagesManager:SendMessage(sender_id, "commands.grantaction.action_not_found", {Action = actionName})
            return
        end
        
        local existingRoleAction = DatabaseManager:getAllEntry(RoleAction, {{"roleID", role.roleID}, {"actionID", action.actionID}})
        if existingRoleAction then
            MessagesManager:SendMessage(sender_id, "commands.grantaction.already_has_action", {Role = rolename, Action = actionName})
        else
            local roleAction = RoleAction.new(role.roleID, action.actionID)
            DatabaseManager:save(roleAction)
            MessagesManager:SendMessage(sender_id, "commands.grantaction.success", {Role = rolename, Action = actionName})
        end
    end)

    return true
end

RegisterNickelCommand("grantaction", command)