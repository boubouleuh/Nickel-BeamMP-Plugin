RoleAction = {}
RoleAction.tableName = "RoleActions"

function RoleAction.new(roleID, actionID)
  local self = {}
  self.tableName = RoleAction.tableName
  self.roleID = roleID
  self.actionID = actionID
  return self
end

function RoleAction.getColumns()
    return {
        "roleID INTEGER",
        "actionID INTEGER",
        "PRIMARY KEY (roleID, actionID)",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID)",
        "FOREIGN KEY (actionID) REFERENCES Actions(actionID) ON DELETE CASCADE"
    }
end