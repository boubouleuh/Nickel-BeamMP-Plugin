
local new = require("objects.New")

-- Classe User
local User = {tableName="Users"}

function User.new(beammpid, name)
  local self = {}

  self.beammpid = beammpid
  self.name = name
  self.permlvl = 0
  self.whitelisted = false

  return new._object(User, self)
end


function User:getBeammpid()
  return self.beammpid
end


function User:getName()
  return self.name
end

function User:getPermlvl()
  return self.permlvl
end


function User:getWhitelisted()
  return self.whitelisted
end

-- Dans la classe User
function User:getColumns()
    return {
      "beammpid INT PRIMARY KEY",
      "name TEXT NOT NULL",
      "permlvl INT NOT NULL",
      "whitelisted BOOLEAN NOT NULL"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return User