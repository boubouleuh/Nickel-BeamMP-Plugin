
local new = require("objects.New")

-- Classe User
local UserRole = {tableName="UserRoles"}

function UserRole.new()
  local self = {}
  self.beammpid = nil
  self.roleID = nil
  return new._object(UserRole, self)
end


function UserRole:getKey(key)
  return self[key]
end

function UserRole:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function UserRole:getColumns()
    return {
        "beammpid INTEGER",
        "roleID INTEGER",
        "PRIMARY KEY (beammpid, roleID)",
        "FOREIGN KEY (beammpid) REFERENCES Users(beammpid)",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID)"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return UserRole