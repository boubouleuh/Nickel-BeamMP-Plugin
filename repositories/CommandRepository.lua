CommandRepository = {}

-- Find command by name
function CommandRepository.findByName(commandName)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Command, "commandName", commandName)
    end)
end

-- Find command by ID
function CommandRepository.findById(commandId)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getEntry(Command, "commandID", commandId)
    end)
end

-- Get all commands
function CommandRepository.findAll()
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllEntry(Command)
    end)
end

-- Save command
function CommandRepository.save(command)
    return DatabaseManager:save(command, true)
end

-- Delete command
function CommandRepository.delete(command)
    return DatabaseManager:withConnection(function()
        return DatabaseManager:deleteObject(Command, {{"commandID", command.commandID}})
    end)
end