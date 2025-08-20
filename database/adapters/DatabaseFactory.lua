-- Database Factory for creating appropriate database adapters
local utils = require("utils.misc")

-- Load adapters with error handling
local SqliteAdapter
local MySQLAdapter

local success, adapter = pcall(require, "database.adapters.SqliteAdapter")
if success then
    SqliteAdapter = adapter
else
    utils.nkprint("Failed to load SQLite adapter: " .. tostring(adapter), "error")
end

local success, adapter = pcall(require, "database.adapters.MySQLAdapter")
if success then
    MySQLAdapter = adapter
else
    utils.nkprint("Failed to load MySQL adapter: " .. tostring(adapter), "error")
end

local DatabaseFactory = {}

-- Create appropriate database adapter based on configuration
function DatabaseFactory.createAdapter(config)
    local dbType = config.database_type or "sqlite"
    dbType = string.lower(dbType)
    
    if dbType == "sqlite" then
        if not SqliteAdapter then
            error("SQLite adapter not available")
        end
        utils.nkprint("Using SQLite database adapter", "info")
        return SqliteAdapter.new(config)
    elseif dbType == "mysql" then
        if not MySQLAdapter then
            utils.nkprint("MySQL adapter not available, falling back to SQLite", "warn")
            if SqliteAdapter then
                -- Update config for SQLite fallback
                local fallbackConfig = {
                    database_type = "sqlite",
                    database_file = config.database_file or "database/nickel_fallback.sqlite"
                }
                return SqliteAdapter.new(fallbackConfig)
            else
                error("No database adapters available")
            end
        end
        
        -- Try to create MySQL adapter, but catch library issues
        local success, adapter = pcall(function()
            return MySQLAdapter.new(config)
        end)
        
        if success and adapter.libraryAvailable then
            utils.nkprint("Using MySQL database adapter", "info")
            return adapter
        else
            utils.nkprint("MySQL library not available, falling back to SQLite", "warn")
            if SqliteAdapter then
                local fallbackConfig = {
                    database_type = "sqlite",
                    database_file = config.database_file or "database/nickel_fallback.sqlite"
                }
                return SqliteAdapter.new(fallbackConfig)
            else
                error("No database adapters available")
            end
        end
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