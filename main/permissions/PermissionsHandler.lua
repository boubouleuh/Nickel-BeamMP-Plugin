local userRole = require("objects.UserRole")
local new = require("objects.New")
local Role = require("objects.Role")



PermissionsHandler = {}

function PermissionsHandler.new(dbManager)
    local self = {}
    self.dbManager = dbManager

    return new._object(PermissionsHandler, self)
end

function PermissionsHandler:addRole(rolename, permlvl, default)
    local newRole = Role.new(rolename, permlvl, default)
    self.dbManager:save(newRole)
end

function PermissionsHandler:removeRole(rolename)
  self.dbManager:deleteObject(Role, "roleName" , rolename)
end

function PermissionsHandler:assignRole(rolename, beammpid)
    local roleid = self.dbManager:getEntry(Role, "roleName", rolename).roleID
    local newUserRole = userRole.new(beammpid,roleid)
    self.dbManager:save(newUserRole)
end

function PermissionsHandler:getDefaultsRoles()
    local roles = self.dbManager:getAllEntry(Role)

    local defaultroles = {}
    for _, role in pairs(roles) do
        if role.is_default == "true" then
          table.insert(defaultroles, role)
        end
    end
    return defaultroles
end

return PermissionsHandler