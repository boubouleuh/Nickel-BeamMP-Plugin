
local new = require("objects.New")

-- Classe User
local Role = {tableName="Roles"}

function Role.new(rolename)
  local self = {}
  self.roleID = nil
  self.roleName = rolename
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
      "roleName TEXT UNIQUE NOT NULL",
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return Role