
local new = require("objects.New")

---@class Action
local Action = {}

Action.tableName = "Actions"

function Action.new(actname)
  local self = {}
  self.actionID = nil
  self.actionName = actname
  return new._object(Action, self)
end


function Action:getKey(key)
  return self[key]
end

function Action:setKey(key, value)
  self[key] = value
end

-- Dans la classe User
function Action:getColumns()
    return {
      "actionID INTEGER PRIMARY KEY AUTOINCREMENT",
	"actionName VARCHAR(191) UNIQUE NOT NULL",
    }
  end
  


return Action