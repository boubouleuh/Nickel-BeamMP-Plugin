
local new = require("objects.New")

---@class UserStatus
local UserStatus = {}

UserStatus.tableName = "UsersStatus"

function UserStatus.new(beammpid, status_type, status_value, reason, expiry_time)
  local self = {}
  self.id = nil
  self.beammpid = beammpid or 0
  self.status_type = status_type or ""
  self.is_status_value = status_value or false
  self.reason = reason or ""
  self.expiry_time = expiry_time or os.time()
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
        "id INTEGER PRIMARY KEY AUTOINCREMENT",
        "beammpid INTEGER NOT NULL",
        "status_type TEXT",
        "is_status_value BOOLEAN NOT NULL",
        "reason TEXT",
        "expiry_time DATETIME",
        "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return UserStatus