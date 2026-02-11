UserStatus = {}
UserStatus.tableName = "UsersStatus"

function UserStatus.new(beammpid, status_type, status_value, reason, expiry_time)
  local self = {}
  self.tableName = UserStatus.tableName
  self.id = nil
  self.beammpid = beammpid or 0
  self.status_type = status_type or ""
  self.is_status_value = status_value or false
  self.reason = reason or ""
  self.expiry_time = expiry_time or nil
  return self
end

function UserStatus.getColumns()
    return {
        "id INTEGER PRIMARY KEY AUTOINCREMENT",
        "beammpid INTEGER NOT NULL",
        "status_type VARCHAR(191)",
        "is_status_value BOOLEAN NOT NULL",
        "reason VARCHAR(191)",
        "expiry_time DATETIME",
        "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
    }
end