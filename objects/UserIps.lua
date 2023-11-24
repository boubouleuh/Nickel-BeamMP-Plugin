local new = require("objects.New")
local utils = require("utils.misc")

-- Classe UserIps
local UserIps = { tableName = "UsersIps" }

function UserIps.new(beammpid, ips)
  local self = {}
  self.id = nil  -- You can set this to a specific value if needed
  self.beammpid = beammpid or 0
  self.ips = {ips} or {}  -- Default to an empty table if no IPs are provided
  return new._object(UserIps, self)
end

function UserIps:getKey(key)
  return self[key]
end

function UserIps:setKey(key, value)
    self[key] = value
end

function UserIps:addIp(ip)
    if not utils.element_exist_in_table(ip, self.ips) then
      
        table.insert(self.ips, ip)
    end
end

-- Dans la classe UserIps
function UserIps:getColumns()
  return {
    "id INTEGER PRIMARY KEY AUTOINCREMENT",
    "beammpid INTEGER",
    "ips TEXT",
    "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
    -- Ajoutez d'autres colonnes si nécessaire
  }
end

return UserIps