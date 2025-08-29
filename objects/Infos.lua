
local new = require("objects.New")

---@class Infos
local Infos = {}

Infos.tableName = "Infos"

function Infos.new(infoKey, infoValue)
  local self = {}
  self.infoID = nil
  self.infoKey = infoKey
  self.infoValue = infoValue
  return new._object(Infos, self)
end


function Infos:getKey(key)
  return self[key]
end

function Infos:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function Infos:getColumns()
    return {
      "infoID INTEGER PRIMARY KEY AUTOINCREMENT",
      "infoKey VARCHAR(191) UNIQUE NOT NULL",
      "infoValue VARCHAR(191) UNIQUE NOT NULL",
      
    }
  end
  


return Infos