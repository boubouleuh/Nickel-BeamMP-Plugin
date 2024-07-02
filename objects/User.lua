
local new = require("objects.New")

-- Classe User
local User = {tableName="Users"}

function User.new(beammpid, name)
  local self = {}
  self.beammpid = beammpid or 0
  self.name = name or ""
  self.whitelisted = false
  self.language = nil
  return new._object(User, self)
end


function User:getKey(key)
  return self[key]
end

function User:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function User:getColumns()
    return {
      "beammpid INTEGER PRIMARY KEY",
      "name TEXT NOT NULL",
      "whitelisted BOOLEAN NOT NULL",
      "language TEXT"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return User