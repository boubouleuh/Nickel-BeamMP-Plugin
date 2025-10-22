UserRoleRepository = {}

-- Find all roles for a user
function UserRoleRepository.findByBeammpid(beammpid)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(UserRole, {{"beammpid", beammpid}})
    end)
end

-- Find all users with a specific role
function UserRoleRepository.findByRoleId(roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(UserRole, {{"roleID", roleId}})
    end)
end

-- Find specific user-role relationship
function UserRoleRepository.findByBeammpidAndRoleId(beammpid, roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(UserRole, {{"beammpid", beammpid}, {"roleID", roleId}})
    end)
end

-- Assign role to user
function UserRoleRepository.save(userRole)
    return DatabaseManager:save(userRole, false)
end

-- Remove role from user
function UserRoleRepository.delete(userRole)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(UserRole, {{"beammpid", userRole.beammpid}, {"roleID", userRole.roleID}})
    end)
end

-- Remove role from user by criteria
function UserRoleRepository.deleteByBeammpidAndRoleId(beammpid, roleId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(UserRole, {{"beammpid", beammpid}, {"roleID", roleId}})
    end)
end

-- Get user roles with role details
function UserRoleRepository.getUserRolesWithDetails(beammpid)
    return DatabaseManager:withConnection(function()
        local roles = {}
        local userRoles = DatabaseManager:getAllEntry(UserRole, {{"beammpid", beammpid}})
        for _, userRole in ipairs(userRoles) do
            local role = DatabaseManager:getEntry(Role, "roleID", userRole.roleID)
            if role then
                table.insert(roles, role)
            end
        end
        return roles
    end)
end