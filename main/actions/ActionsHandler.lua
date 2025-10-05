ActionsManager = {}

NickelActions = NickelActions or {}

function RegisterNickelAction(name, actionData)
    NickelActions[name] = actionData
end

--- init actions
function ActionsManager.init()

    local actionCount = Utils.tableLength(NickelActions)
    Utils.nkprint("[ActionsHandler] Initializing with " .. tostring(actionCount) .. " registered actions", "info")

    for actionName, actionData in pairs(NickelActions) do
        Utils.nkprint("[ActionsHandler] Found registered action: " .. actionName, "debug")
        local action = Action.new(actionName)
        DatabaseManager:save(action)
    end

    local function checkActions()
        DatabaseManager:withConnection(function()
            local actionsFromDB = DatabaseManager:getAllEntry(Action)

            -- Remove actions not present in memory from the database
            for _, action in pairs(actionsFromDB) do
                if not NickelActions[action.actionName] then
                    local conditions = {
                        {"actionName", action.actionName},
                    }

                    DatabaseManager:deleteObject(Action, conditions)
                    print("Removed obsolete action from database: " .. action.actionName)
                end
            end
        end)
    end

    checkActions()

end

function ActionsManager:GetActions()
    return Utils.shallowCopy(NickelActions)
end
