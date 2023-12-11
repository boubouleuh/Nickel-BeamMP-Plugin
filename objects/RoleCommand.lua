
local new = require("objects.New")

-- Classe User
local RoleCommand = {tableName="RoleCommands"}

function RoleCommand.new()
  local self = {}
  self.roleID = nil
  self.commandID = nil
  return new._object(RoleCommand, self)
end


function RoleCommand:getKey(key)
  return self[key]
end

function RoleCommand:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function RoleCommand:getColumns()
    return {
        "roleID INTEGER",
        "commandID INTEGER",
        "PRIMARY KEY (roleID, commandID)",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID)",
        "FOREIGN KEY (commandID) REFERENCES Commands(commandID) ON DELETE CASCADE"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return RoleCommand