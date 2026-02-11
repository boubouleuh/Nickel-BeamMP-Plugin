UserRole = {}
UserRole.tableName = "UserRoles"

function UserRole.new(beammpid, roleid)
  local self = {}
  self.tableName = UserRole.tableName
  self.beammpid = beammpid
  self.roleID = roleid
  return self
end

function UserRole.getColumns()
    return {
        "beammpid INTEGER",
        "roleID INTEGER",
        "PRIMARY KEY (beammpid, roleID)",
        "FOREIGN KEY (beammpid) REFERENCES Users(beammpid) ON DELETE CASCADE",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID) ON DELETE CASCADE"
    }
end