RoleCommand = {}
RoleCommand.tableName = "RoleCommands"

function RoleCommand.new(roleID, commandID)
  local self = {}
  self.tableName = RoleCommand.tableName
  self.roleID = roleID
  self.commandID = commandID
  return self
end

function RoleCommand.getColumns()
    return {
        "roleID INTEGER",
        "commandID INTEGER",
        "PRIMARY KEY (roleID, commandID)",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID)",
        "FOREIGN KEY (commandID) REFERENCES Commands(commandID) ON DELETE CASCADE"
    }
end