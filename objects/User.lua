
User = {}
User.tableName = "Users"

function User.new(beammpid, name)
  local self = {}
  self.beammpid = beammpid or 0
  self.name = name or ""
  self.whitelisted = false
  self.language = nil
  return self
end


function User.getColumns()
    return {
      "beammpid INTEGER PRIMARY KEY",
      "name TEXT NOT NULL",
      "whitelisted BOOLEAN NOT NULL",
      "language TEXT"
    }
end