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
      "actionName TEXT UNIQUE NOT NULL",
    }
end