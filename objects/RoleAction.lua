local new = require("objects.New")

---@class RoleAction
local RoleAction = {}

RoleAction.tableName = "RoleActions"

function RoleAction.new(roleID, actionID)
  local self = {}
  self.roleID = roleID
  self.actionID = actionID
  return new._object(RoleAction, self)
end


function RoleAction:getKey(key)
  return self[key]
end

function RoleAction:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function RoleAction:getColumns()
    return {
        "roleID INTEGER",
        "actionID INTEGER",
        "PRIMARY KEY (roleID, actionID)",
        "FOREIGN KEY (roleID) REFERENCES Roles(roleID)",
        "FOREIGN KEY (actionID) REFERENCES Actions(actionID) ON DELETE CASCADE"
      -- Ajoutez d'autres colonnes si nécessaire
    }
  end
  


return RoleAction