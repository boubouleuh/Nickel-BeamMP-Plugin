RoleRepository = {}

-- Find role by name
function RoleRepository.findByName(roleName)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Role, "roleName", roleName)
    end)
end

-- Find role by ID
function RoleRepository.findById(roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Role, "roleID", roleId)
    end)
end

-- Find role by permission level
function RoleRepository.findByPermissionLevel(permLevel)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Role, "permlvl", tostring(permLevel))
    end)
end

-- Get all roles
function RoleRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Role)
    end)
end

-- Get all default roles
function RoleRepository.findAllDefault()
    return DatabaseManager:withConnection(function()
        local roles = DatabaseManager:getAllEntry(Role)
        local defaultRoles = {}
        for _, role in pairs(roles) do
            if Utils.isTruthy(role.is_default) then
                table.insert(defaultRoles, role)
            end
        end
        return defaultRoles
    end)
end

-- Save role
function RoleRepository.save(role)
    return DatabaseManager:save(role, true)
end

-- Delete role
function RoleRepository.delete(role)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(Role, {{"roleID", role.roleID}})
    end)
end