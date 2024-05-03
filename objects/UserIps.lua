local new = require("objects.New")
local utils = require("utils.misc")

-- Classe UserIps
local UserIps = { tableName = "UsersIps" }

function UserIps.new(beammpid, ip)
  local self = {}
  self.ip_id = nil  -- You can set this to a specific value if needed
  self.beammpid = beammpid
  self.ip = ip
  self.banned = false
  return new._object(UserIps, self)
end

function UserIps:getKey(key)
  return self[key]
end

function UserIps:setKey(key, value)
    self[key] = value
end


-- Dans la classe UserIps
function UserIps:getColumns()
  return {
    "ip_id INTEGER PRIMARY KEY AUTOINCREMENT",
    "beammpid INTEGER",
    "ip TEXT UNIQUE",
    "banned BOOLEAN",
    "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
    -- Ajoutez d'autres colonnes si nécessaire
  }
end

return UserIps