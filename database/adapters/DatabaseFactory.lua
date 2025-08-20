-- Database Factory for creating appropriate database adapters
local SqliteAdapter = require("database.adapters.SqliteAdapter")
local MySQLAdapter = require("database.adapters.MySQLAdapter")
local utils = require("utils.misc")

local DatabaseFactory = {}

-- Create appropriate database adapter based on configuration
function DatabaseFactory.createAdapter(config)
    local dbType = config.database_type or "sqlite"
    dbType = string.lower(dbType)
    
    if dbType == "sqlite" then
        utils.nkprint("Using SQLite database adapter", "info")
        return SqliteAdapter.new(config)
    elseif dbType == "mysql" then
        utils.nkprint("Using MySQL database adapter", "info")
        return MySQLAdapter.new(config)
    else
        error("Unsupported database type: " .. tostring(dbType) .. ". Supported types: sqlite, mysql")
    end
end

-- Get list of supported database types
function DatabaseFactory.getSupportedTypes()
    return {"sqlite", "mysql"}
end

-- Validate database configuration
function DatabaseFactory.validateConfig(config)
    local dbType = config.database_type or "sqlite"
    dbType = string.lower(dbType)
    
    if dbType == "sqlite" then
        if not config.database_file or config.database_file == "" then
            utils.nkprint("Warning: SQLite database_file not specified, using default path", "warn")
            return true
        end
        return true
    elseif dbType == "mysql" then
        local requiredFields = {"mysql_host", "mysql_database", "mysql_username"}
        for _, field in ipairs(requiredFields) do
            if not config[field] or config[field] == "" then
                utils.nkprint("Error: MySQL configuration missing required field: " .. field, "error")
                return false
            end
        end
        return true
    end
    
    return false
end

return DatabaseFactory