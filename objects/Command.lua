
local new = require("objects.New")

---@class Command
local Command = {}

Command.tableName = "Commands"

function Command.new(cmdname)
  local self = {}
  self.commandID = nil
  self.commandName = cmdname
  return new._object(Command, self)
end


function Command:getKey(key)
  return self[key]
end

function Command:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function Command:getColumns()
    return {
      "commandID INTEGER PRIMARY KEY AUTOINCREMENT",
      "commandName TEXT UNIQUE NOT NULL",
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return Command