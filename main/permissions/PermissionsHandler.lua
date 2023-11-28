
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
    print(rolename, permlvl, default)
    self.dbManager:save(newRole)
end

function PermissionsHandler:removeRole(rolename)
  self.dbManager:deleteObject(Role, "roleName" , rolename)
end



return PermissionsHandler