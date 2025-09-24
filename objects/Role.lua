
Role = {}
Role.tableName = "Roles"

function Role.new(rolename, permlvl, is_default)
  local self = {}
  self.tableName = Role.tableName
  self.roleID = nil
  self.roleName = rolename
  self.permlvl = permlvl
  self.is_default = is_default
  return self
end


function Role.getColumns()
    return {
      "roleID INTEGER PRIMARY KEY AUTOINCREMENT",
      "roleName VARCHAR(191) UNIQUE NOT NULL",
      "permlvl INT NOT NULL",
      "is_default BOOLEAN NOT NULL",
    }
end