Action = {}
Action.tableName = "Actions"

function Action.new(actname)
  local self = {}
  self.tableName = Action.tableName
  self.actionID = nil
  self.actionName = actname
  return self
end

function Action.getColumns()
    return {
      "actionID INTEGER PRIMARY KEY AUTOINCREMENT",
      "actionName VARCHAR(191) UNIQUE NOT NULL",
    }
end