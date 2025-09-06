ActionRepository = {}

-- Find action by name
function ActionRepository.findByName(actionName)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Action, "actionName", actionName)
    end)
end

-- Find action by ID
function ActionRepository.findById(actionId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Action, "actionID", actionId)
    end)
end

-- Get all actions
function ActionRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Action)
    end)
end

-- Save action
function ActionRepository.save(action)
    return DatabaseManager:save(action, true)
end

-- Delete action
function ActionRepository.delete(action)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(Action, {{"actionID", action.actionID}})
    end)
end