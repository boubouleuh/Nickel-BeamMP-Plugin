RoleCommandRepository = {}

-- Find role-command relationships by role and command
function RoleCommandRepository.findByRoleAndCommand(roleId, commandId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleCommand, {{"roleID", roleId}, {"commandID", commandId}})
    end)
end

-- Find all role-command relationships for a role
function RoleCommandRepository.findByRole(roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleCommand, {{"roleID", roleId}})
    end)
end

-- Find all role-command relationships for a command
function RoleCommandRepository.findByCommand(commandId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleCommand, {{"commandID", commandId}})
    end)
end

-- Get all role-command relationships
function RoleCommandRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(RoleCommand)
    end)
end

-- Save role-command relationship
function RoleCommandRepository.save(roleCommand)
    return DatabaseManager:save(roleCommand, false)
end

-- Delete role-command relationship
function RoleCommandRepository.delete(roleCommand)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(RoleCommand, {{"roleID", roleCommand.roleID}, {"commandID", roleCommand.commandID}})
    end)
end