
local new = require("objects.New")

-- Classe User
local UserStatus = {tableName="UsersStatus"}

function UserStatus.new(beammpid, status_type, status_value, reason, time)
  local self = {}

  self.beammpid = beammpid or 0
  self.status_type = status_type or ""
  self.status_value = status_value or false
  self.reason = reason or ""
  self.time = time or os.time()
  return new._object(UserStatus, self)
end


function UserStatus:getKey(key)
  return self[key]
end


function UserStatus:setKey(key, value)
    self[key] = value
end

-- Dans la classe UserStatus
function UserStatus:getColumns()
    return {
        "beammpid INT PRIMARY KEY",
        "status_type TEXT",
        "status_value BOOLEAN",
        "reason TEXT",
        "time DATETIME",
        "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return UserStatus