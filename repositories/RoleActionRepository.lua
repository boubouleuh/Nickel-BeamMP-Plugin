RoleActionRepository = {}

-- Find role-action relationships by role and action
function RoleActionRepository.findByRoleAndAction(roleId, actionId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleAction, {{"roleID", roleId}, {"actionID", actionId}})
    end)
end

-- Find all role-action relationships for a role
function RoleActionRepository.findByRole(roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleAction, {{"roleID", roleId}})
    end)
end

-- Find all role-action relationships for an action
function RoleActionRepository.findByAction(actionId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleAction, {{"actionID", actionId}})
    end)
end

-- Get all role-action relationships
function RoleActionRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleAction)
    end)
end

-- Save role-action relationship
function RoleActionRepository.save(roleAction)
    return DatabaseManager:save(roleAction, true)
end

-- Delete role-action relationship
function RoleActionRepository.delete(roleAction)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(RoleAction, {{"roleID", roleAction.roleID}, {"actionID", roleAction.actionID}})
    end)
end