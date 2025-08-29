
local new = require("objects.New")

---@class Role
local Role = {}

Role.tableName = "Roles"

function Role.new(rolename, permlvl, is_default)
  local self = {}
  self.roleID = nil
  self.roleName = rolename
  self.permlvl = permlvl
  self.is_default = is_default
  return new._object(Role, self)
end


function Role:getKey(key)
  return self[key]
end

function Role:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function Role:getColumns()
    return {
      "roleID INTEGER PRIMARY KEY AUTOINCREMENT",
      "roleName VARCHAR(191) UNIQUE NOT NULL",
      "permlvl INT NOT NULL",
      "is_default BOOLEAN NOT NULL",
      
    }
  end
  


return Role