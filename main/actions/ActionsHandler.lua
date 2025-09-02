ActionsHandler = {}

NickelActions = NickelActions or {}

function RegisterNickelAction(name, actionData)
    NickelActions[name] = actionData
    print("Registered action: " .. name)
end

--- init actions
function ActionsHandler.init()
    local self = {
        actions = {}
    }
    setmetatable(self, { __index = ActionsHandler })
    
    for actionName, actionData in pairs(NickelActions or {}) do
        local action = Action.new(actionName)
        DatabaseManager:save(action)
        
        self.actions[actionName] = actionData
    end

    local function checkActions()
        DatabaseManager:withConnection(function()
            local actionsFromDB = DatabaseManager:getAllEntry(Action)

            -- Remove actions not present in memory from the database
            for _, action in pairs(actionsFromDB) do
                if not self.actions[action.actionName] then
                    local conditions = {
                        {"actionName", action.actionName},
                    }

                    DatabaseManager:deleteObject(Action, conditions)
                end
            end
        end)
    end

    checkActions()

    return self
end

function ActionsHandler:GetActions()
    return self.actions
end

return ActionsHandler
