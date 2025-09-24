Command = {}
Command.tableName = "Commands"

function Command.new(cmdname)
  local self = {}
  self.tableName = Command.tableName
  self.commandID = nil
  self.commandName = cmdname
  return self
end

function Command.getColumns()
    return {
      "commandID INTEGER PRIMARY KEY AUTOINCREMENT",
      "commandName VARCHAR(191) UNIQUE NOT NULL",
    }
end