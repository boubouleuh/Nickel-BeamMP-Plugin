local new = require("objects.New")
local utils = require("utils.misc")

---@class UserIp
local UserIp = {}

UserIp.tableName = "UserIps" 

function UserIp.new(beammpid, ip)
  local self = {}
  self.ip_id = nil  -- You can set this to a specific value if needed
  self.beammpid = beammpid
  self.ip = ip
  self.is_banned = false
  return new._object(UserIp, self)
end

function UserIp:getKey(key)
  return self[key]
end

function UserIp:setKey(key, value)
    self[key] = value
end


-- Dans la classe UserIps
function UserIp:getColumns()
  return {
    "ip_id INTEGER PRIMARY KEY AUTOINCREMENT",
    "beammpid INTEGER",
    "ip TEXT UNIQUE",
    "is_banned BOOLEAN NOT NULL",
    "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
    -- Ajoutez d'autres colonnes si nécessaire
  }
end

return UserIp