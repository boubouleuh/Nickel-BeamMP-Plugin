local UserRole = require("objects.UserRole")
local new = require("objects.New")
local Role = require("objects.Role")
local Command = require("objects.Command")
local sqlcodes = require("database.sqlresultcode")
local RoleCommand = require("objects.RoleCommand")
PermissionsHandler = {}

function PermissionsHandler.new(dbManager)
    local self = {}
    self.dbManager = dbManager

    return new._object(PermissionsHandler, self)
end

function PermissionsHandler:addRole(rolename, permlvl, default)
    local newRole = Role.new(rolename, permlvl, default)
    local result = self.dbManager:save(newRole)
    return result
end

function PermissionsHandler:removeRole(rolename)
  self.dbManager:openConnection()
  
  local conditions = {
    {"roleName", rolename},
  }
  local result = self.dbManager:deleteObject(Role, conditions)
  self.dbManager:closeConnection()
  return result
end

function PermissionsHandler:assignRole(rolename, beammpid)
    self.dbManager:openConnection()
    local roleid = self.dbManager:getEntry(Role, "roleName", rolename).roleID
    self.dbManager:closeConnection()

    local newUserRole = UserRole.new(beammpid,roleid)
    local result = self.dbManager:save(newUserRole, false)

    return result
end

function PermissionsHandler:unassignRole(rolename, beammpid)
    self.dbManager:openConnection()
   
    local roleid = self.dbManager:getEntry(Role, "roleName", rolename).roleID

    local conditions = {
        {"roleID", roleid},
        {"beammpid", beammpid}
    }

    local result = self.dbManager:deleteObject(UserRole, conditions)
    self.dbManager:closeConnection()
    return result
end

function PermissionsHandler:getDefaultsRoles()
    self.dbManager:openConnection()
    local roles = self.dbManager:getAllEntry(Role)
    self.dbManager:closeConnection()
    local defaultroles = {}
    for _, role in pairs(roles) do
        if role.is_default == "true" then
          table.insert(defaultroles, role)
        end
    end
    return defaultroles
end




function PermissionsHandler:assignCommand(commandname, rolename)
    self.dbManager:openConnection()
    local commandid = self.dbManager:getEntry(Command, "commandName", commandname).commandID
    local roleid = self.dbManager:getEntry(Role, "roleName", rolename).roleID
    self.dbManager:closeConnection()

    local newRoleCommand = RoleCommand.new(roleid, commandid)
    local result = self.dbManager:save(newRoleCommand, false)

    return result
end

function PermissionsHandler:unassignCommand(commandname, rolename)
    self.dbManager:openConnection()
    local commandid = self.dbManager:getEntry(Command, "commandName", commandname).commandID
    local roleid = self.dbManager:getEntry(Role, "roleName", rolename).roleID

    local conditions = {
        {"roleID", roleid},
        {"commandID", commandid}
    }

    local result = self.dbManager:deleteObject(RoleCommand, conditions)
    self.dbManager:closeConnection()

    return result
end

function PermissionsHandler:getRoles(beammpid)

    local roles = {}

    -- Récupérer tous les rôles de l'utilisateur avec l'ID beammpid
    local userRoles = self.dbManager:getAllEntry(UserRole, {{"beammpid", beammpid}})
    for _, userRole in ipairs(userRoles) do
        local role = self.dbManager:getEntry(Role, "roleID", userRole.roleID)
        if role then
            table.insert(roles, role)
        end
    end


    return roles
end


function PermissionsHandler:canManageRole(manager_beammpid, rolename)
    self.dbManager:openConnection()

    -- Obtenir tous les rôles du gestionnaire
    local managerRoles = self:getRoles(manager_beammpid)
    if #managerRoles == 0 then
        -- Si le gestionnaire n'a pas de rôles, il ne peut pas ajouter de rôles
        self.dbManager:closeConnection()
        return false
    end

    -- Vérifier si le gestionnaire a la permission d'ajouter le rôle spécifié
    local rolePermLvl = self.dbManager:getEntry(Role, "roleName", rolename).permlvl

    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > rolePermLvl then
            self.dbManager:closeConnection()
            return true
        end
    end

    self.dbManager:closeConnection()
    return false
end

function PermissionsHandler:canManage(manager_beammpid, managed_beammpid)
    self.dbManager:openConnection()

    -- Obtenir tous les rôles du gestionnaire
    local managerRoles = self:getRoles(manager_beammpid)
    if #managerRoles == 0 then
        -- Si le gestionnaire n'a pas de rôles, il ne peut pas gérer
        self.dbManager:closeConnection()
        return false
    end

    -- Obtenir tous les rôles du géré
    local managedRoles = self:getRoles(managed_beammpid)
    if #managedRoles == 0 then
        -- Si le géré n'a pas de rôles, le gestionnaire ne peut pas le gérer
        self.dbManager:closeConnection()
        return false
    end

    -- Déterminer le niveau de permission le plus élevé parmi les rôles du géré
    local maxManagedRoleLevel = 0
    for _, managedRole in ipairs(managedRoles) do
        if managedRole.permlvl > maxManagedRoleLevel then
            maxManagedRoleLevel = managedRole.permlvl
        end
    end

    -- Vérifier si le gestionnaire a un rôle avec un niveau de permission supérieur à celui du géré
    for _, managerRole in ipairs(managerRoles) do
        if managerRole.permlvl > maxManagedRoleLevel then
            self.dbManager:closeConnection()
            return true
        end
    end

    self.dbManager:closeConnection()
    return false
end







function PermissionsHandler:hasPermission(beammpid, commandname)
    self.dbManager:openConnection()

    if beammpid == -2 then
        return true     -- if it's the console, give full permission
    end

    -- Obtenir tous les rôles de l'utilisateur
    local userRoles = self:getRoles(beammpid)
    local commandId = self.dbManager:getEntry(Command, "commandName", commandname).commandID

    -- Vérifier si l'un des rôles de l'utilisateur a la permission pour la commande
    for _, userRole in ipairs(userRoles) do
        local roleId = userRole.roleID
        local conditions = {
            {"roleID", roleId},
            {"commandID", commandId}
        }

        local roleCommandEntries = self.dbManager:getAllEntry(RoleCommand, conditions)

        if #roleCommandEntries > 0 then
            self.dbManager:closeConnection()
            return true
        end
    end

    -- Si l'utilisateur n'a pas la permission avec ses rôles actuels, vérifier les niveaux de permission inférieurs
    for _, userRole in ipairs(userRoles) do
        local roleId = userRole.roleID
        local role = self.dbManager:getEntry(Role, "roleID", roleId)
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = self.dbManager:getEntry(Role, "permlvl", tostring(lowerPermissions))
            if lowerRole then
                local lowerConditions = {
                    {"roleID", lowerRole.roleID},
                    {"commandID", commandId}
                }

                local lowerRoleCommandEntries = self.dbManager:getAllEntry(RoleCommand, lowerConditions)

                if #lowerRoleCommandEntries > 0 then
                    self.dbManager:closeConnection()
                    return true
                end
            end
            lowerPermissions = lowerPermissions - 1
        end
    end

    self.dbManager:closeConnection()
    return false
end



--todo need to fix permission check on lower perm


return PermissionsHandler