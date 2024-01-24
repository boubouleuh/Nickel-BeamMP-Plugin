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

function PermissionsHandler:hasPermission(beammpid, commandname)
    self.dbManager:openConnection()

    -- Obtenir l'ID du rôle de l'utilisateur
    local userRole = self.dbManager:getEntry(UserRole, "beammpid", beammpid)
    local roleId = userRole and userRole.roleID or nil

    -- Obtenir l'ID de la commande
    local commandId = self.dbManager:getEntry(Command, "commandName", commandname).commandID

    -- Vérifier si le rôle de l'utilisateur a la permission pour la commande
    local conditions = {
        {"roleID", roleId},
        {"commandID", commandId}
    }

    local roleCommandEntries = self.dbManager:getAllEntry(RoleCommand)

    for _, entry in ipairs(roleCommandEntries) do
        local match = true
        for _, condition in ipairs(conditions) do
            if entry[condition[1]] ~= condition[2] then
                match = false
                break
            end
        end

        if match then
            self.dbManager:closeConnection()
            return true
        end
    end

    -- Si l'utilisateur n'a pas la permission, vérifier les niveaux de permission inférieurs
    if roleId then
        local role = self.dbManager:getEntry(Role, "roleID", roleId)
        local lowerPermissions = role and tonumber(role.permlvl) - 1 or 0

        while lowerPermissions >= 0 do
            local lowerRole = self.dbManager:getEntry(Role, "permlvl", tostring(lowerPermissions))
            if lowerRole then
                local lowerConditions = {
                    {"roleID", lowerRole.roleID},
                    {"commandID", commandId}
                }

                local lowerRoleCommandEntries = self.dbManager:getAllEntry(RoleCommand)

                for _, entry in ipairs(lowerRoleCommandEntries) do
                    local match = true
                    for _, condition in ipairs(lowerConditions) do
                        if entry[condition[1]] ~= condition[2] then
                            match = false
                            break
                        end
                    end

                    if match then
                        self.dbManager:closeConnection()
                        return true
                    end
                end
            end
            lowerPermissions = lowerPermissions - 1
        end
    end

    self.dbManager:closeConnection()
    return false
end





return PermissionsHandler