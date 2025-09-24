PermissionsManager = {}

function PermissionsManager:addRole(rolename, permlvl, default)
    local newRole = Role.new(rolename, permlvl, default)
    local result = DatabaseManager:save(newRole, false)
    return result
end

function PermissionsManager:removeRole(rolename)
  return DatabaseManager:withConnection(function()
    local conditions = {
        {"roleName", rolename},
    }
    return DatabaseManager:deleteObject(Role, conditions)
  end)
end

function PermissionsManager:assignRole(rolename, beammpid)
    return DatabaseManager:withConnection(function()
        local roleid = DatabaseManager:getEntry(Role, "roleName", rolename).roleID

        local newUserRole = UserRole.new(beammpid, roleid)
        return DatabaseManager:save(newUserRole, false)
    end)
end


function PermissionsManager:unassignRole(rolename, beammpid)
    return DatabaseManager:withConnection(function()
        local role = DatabaseManager:getEntry(Role, "roleName", rolename)
        if role.is_default == 1 then
            return 516
        end
        local roleid = role.roleID
        local conditions = {
            {"roleID", roleid},
            {"beammpid", beammpid}
        }

        return DatabaseManager:deleteObject(UserRole, conditions)
    end)
end

function PermissionsManager:getDefaultsRoles()
    local roles = DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Role)
    end)
    local defaultroles = {}
    for _, role in pairs(roles) do
        if role.is_default == 1 then
          table.insert(defaultroles, role)
        end
    end
    return defaultroles
end


function PermissionsManager:getCommands(beammpid)
    local commands = {}

    local allCommands = DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Command)
    end)
    for _, command in ipairs(allCommands) do
        if self:hasPermission(beammpid, command.commandName) then
            table.insert(commands, command)
        end
    end
    return commands
end


function PermissionsManager:assignCommand(commandname, rolename)
    local commandid, roleid = DatabaseManager:withConnection(function()
        local commandid = DatabaseManager:getEntry(Command, "commandName", commandname).commandID
        local roleid = DatabaseManager:getEntry(Role, "roleName", rolename).roleID
        return commandid, roleid
    end)
    local newRoleCommand = RoleCommand.new(roleid, commandid)
    local result = DatabaseManager:save(newRoleCommand, false)

    return result
end

function PermissionsManager:assignAction(actionname, rolename)
    local actionid, roleid = DatabaseManager:withConnection(function()
        local actionid = DatabaseManager:getEntry(Action, "actionName", actionname).actionID
        local roleid = DatabaseManager:getEntry(Role, "roleName", rolename).roleID
        return actionid, roleid
    end)

    local newRoleAction = RoleAction.new(roleid, actionid)
    local result = DatabaseManager:save(newRoleAction, false)

    return result
end

function PermissionsManager:unassignAction(actionname, rolename)
    local result = DatabaseManager:withConnection(function()
        local actionid = DatabaseManager:getEntry(Action, "actionName", actionname).actionID
        local roleid = DatabaseManager:getEntry(Role, "roleName", rolename).roleID

        local conditions = {
            {"roleID", roleid},
            {"actionID", actionid}
        }

        return DatabaseManager:deleteObject(RoleAction, conditions)
    end)

    return result
end

--getActions
function PermissionsManager:getActions(beammpid)

    local actions = {}

    local allActions = DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Action)
    end)

    for _, action in ipairs(allActions) do
        if self:hasPermissionForAction(beammpid, action.actionName) then
            table.insert(actions, action)
        end
    end

    return actions
end

function PermissionsManager:unassignCommand(commandname, rolename)
    local result = DatabaseManager:withConnection(function()
        local commandid = DatabaseManager:getEntry(Command, "commandName", commandname).commandID
        local roleid = DatabaseManager:getEntry(Role, "roleName", rolename).roleID

        local conditions = {
            {"roleID", roleid},
            {"commandID", commandid}
        }

        return DatabaseManager:deleteObject(RoleCommand, conditions)
    end)

    return result
end

function PermissionsManager:getRoles(beammpid)

    local roles = DatabaseManager:withConnection(function()
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

    return roles
end

function PermissionsManager:GetHighestRole(beammpid)
    local roles = self:getRoles(beammpid)
    local highestRole = nil
    for _, role in ipairs(roles) do
        if highestRole == nil or role.permlvl > highestRole.permlvl then
            highestRole = role
        end
    end
    return highestRole
end

function PermissionsManager:canManageRole(manager_beammpid, rolename)
    local managerRoles = self:getRoles(manager_beammpid)
    if #managerRoles == 0 then
        return false
    end

    local rolePermLvl = DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Role, "roleName", rolename).permlvl
    end)

    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > rolePermLvl then
            return true
        end
    end
    return false
end

function PermissionsManager:canManage(manager_beammpid, managed_beammpid)
    local managerRoles = self:getRoles(manager_beammpid)
    if #managerRoles == 0 then
        return false
    end

    local managedRoles = self:getRoles(managed_beammpid)
    if #managedRoles == 0 then
        return false
    end

    local maxManagedRoleLevel = 0
    for _, managedRole in ipairs(managedRoles) do
        if managedRole.permlvl > maxManagedRoleLevel then
            maxManagedRoleLevel = managedRole.permlvl
        end
    end

    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > maxManagedRoleLevel then
            return true
        end
    end

    return false
end





function PermissionsManager:hasPermissionForAction(beammpid, actionName)
    if beammpid == -2 then
        return true     -- if it's the console, give full permission
    end

    local userRoles = self:getRoles(beammpid)
    local action = ActionRepository.findByName(actionName)


    local roleActionEntries = DatabaseManager:withConnection(function()
        local entries = {}
        for _, userRole in ipairs(userRoles) do
            local roleId = userRole.roleID
            local conditions = {
                {"roleID", roleId},
                {"actionID", action.id}
            }

            table.insert(entries, DatabaseManager:getAllEntry(RoleAction, conditions))
            
        end
        return entries
    end)

    if #roleActionEntries > 0 then
        return true
    end

    local bool = DatabaseManager:withConnection(function()
        for _, userRole in ipairs(userRoles) do
            local roleId = userRole.roleID
            local role = DatabaseManager:getEntry(Role, "roleID", roleId)
            local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

            while lowerPermissions >= 0 do
                local lowerRole = DatabaseManager:getEntry(Role, "permlvl", tostring(lowerPermissions))
                if lowerRole then
                    local lowerConditions = {
                        {"roleID", lowerRole.roleID},
                        {"actionID", action.id}
                    }

                    local lowerRoleActionEntries = DatabaseManager:getAllEntry(RoleAction, lowerConditions)

                    if #lowerRoleActionEntries > 0 then
                        return true
                    end
                end
                lowerPermissions = lowerPermissions - 1
            end
        end
        return false
    end)
    return bool
end

function PermissionsManager:hasPermission(beammpid, commandName)
    if beammpid == -2 then
        return true     -- if it's the console, give full permission
    end

    local userRoles = self:getRoles(beammpid)
    local command = CommandRepository.findByName(commandName)

    local roleCommandEntries = DatabaseManager:withConnection(function()
        local entries = {}
        for _, userRole in ipairs(userRoles) do
            local roleId = userRole.roleID
            local conditions = {
                {"roleID", roleId},
                {"commandID", command.id}
            }
            table.insert(entries, DatabaseManager:getAllEntry(RoleCommand, conditions))
        end
        return entries

    end)
    if #roleCommandEntries > 0 then
        return true
    end
    local bool = DatabaseManager:withConnection(function()
        for _, userRole in ipairs(userRoles) do
            local roleId = userRole.roleID
            local role = DatabaseManager:getEntry(Role, "roleID", roleId)
            local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

            while lowerPermissions >= 0 do
                local lowerRole = DatabaseManager:getEntry(Role, "permlvl", tostring(lowerPermissions))
                if lowerRole then
                    local lowerConditions = {
                        {"roleID", lowerRole.roleID},
                        {"commandID", command.id}
                    }

                    local lowerRoleCommandEntries = DatabaseManager:getAllEntry(RoleCommand, lowerConditions)

                    if #lowerRoleCommandEntries > 0 then
                        return true
                    end
                end
                lowerPermissions = lowerPermissions - 1
            end
        end
        return false
    end)
    return bool
end
