
local command = RegisterCommand("revokeaction", {
    args = {
        {name = "actionName", type = "string"},
        {name = "rolename", type = "string"}
    }
})

--- command
function command.init(sender_id, sender_name, actionName, rolename)
    if actionName == nil or rolename == nil then
        MessagesManager:SendMessage(sender_id, "commands.revokeaction.missing_args", {Prefix = ConfigManager.GetSetting("commands").prefix})
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
        MessagesManager:SendMessage(sender_id, "commands.revokeaction.role_not_found", {Role = rolename})
        return false
    end
    
    local action = ActionRepository.findByName(actionName)
    if not action then
        MessagesManager:SendMessage(sender_id, "commands.revokeaction.action_not_found", {Action = actionName})
        return false
    end
    
    local existingRoleAction = RoleActionRepository.findByRoleAndAction(role.roleID, action.actionID)
    if not existingRoleAction or #existingRoleAction == 0 then
        MessagesManager:SendMessage(sender_id, "commands.revokeaction.does_not_have_action", {Role = rolename, Action = actionName})
        return false
    end
    
    local code = RoleActionRepository.delete(existingRoleAction[1])
    MessagesManager:SendMessage(sender_id, "database.code." .. code)
    
    return true
end


