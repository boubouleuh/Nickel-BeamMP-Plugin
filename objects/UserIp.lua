UserIp = {}
UserIp.tableName = "UserIps"

function UserIp.new(beammpid, ip)
  local self = {}
  self.ip_id = nil
  self.beammpid = beammpid
  self.ip = ip
  self.is_banned = false
  return self
end

function UserIp.getColumns()
  return {
    "ip_id INTEGER PRIMARY KEY AUTOINCREMENT",
    "beammpid INTEGER",
    "ip TEXT UNIQUE",
    "is_banned BOOLEAN NOT NULL",
    "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE"
  }
end