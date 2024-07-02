
local new = require("objects.New")

-- Classe User
local infos = {tableName="Infos"}

function infos.new(infoKey, infoValue)
  local self = {}
  self.infoID = nil
  self.infoKey = infoKey
  self.infoValue = infoValue
  return new._object(infos, self)
end


function infos:getKey(key)
  return self[key]
end

function infos:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function infos:getColumns()
    return {
      "infoID INTEGER PRIMARY KEY AUTOINCREMENT",
      "infoKey TEXT UNIQUE NOT NULL",
      "infoValue TEXT UNIQUE NOT NULL",
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return infos