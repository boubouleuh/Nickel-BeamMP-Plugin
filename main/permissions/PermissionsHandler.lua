local userRole = require("objects.UserRole")
local new = require("objects.New")
local Role = require("objects.Role")

local sqlcodes = require("database.sqlresultcode")

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

    local newUserRole = userRole.new(beammpid,roleid)
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

    local result = self.dbManager:deleteObject(userRole, conditions)
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

return PermissionsHandler