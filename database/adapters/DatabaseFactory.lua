DatabaseFactory = {}

-- Create appropriate database adapter based on configuration
function DatabaseFactory.createAdapter(config)
    local dbType = config.database_type or "sqlite"
    dbType = string.lower(dbType)
    
    if dbType == "sqlite" then
        if not SqliteAdapter then
            error("SQLite adapter not available")
        end
        Utils.nkprint("Using SQLite database adapter", "info")
        return SqliteAdapter.new(config)
    elseif dbType == "mysql" then
        if not MySQLAdapter then
            Utils.nkprint("MySQL adapter not available, falling back to SQLite", "warn")
            if SqliteAdapter then
                -- Update config for SQLite fallback
                local fallbackConfig = {
                    database_type = "sqlite",
                    database_file = config.database_file or Utils.script_path() .. "database/nickel_fallback.db"
                }
                return SqliteAdapter.new(fallbackConfig)
            else
                error("No database adapters available")
            end
        end
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
            Utils.nkprint("Warning: SQLite database_file not specified, using default path", "warn")
            return true
        end
        return true
    elseif dbType == "mysql" then
        local requiredFields = {"mysql_host", "mysql_database", "mysql_username"}
        for _, field in ipairs(requiredFields) do
            if not config[field] or config[field] == "" then
                Utils.nkprint("Error: MySQL configuration missing required field: " .. field, "error")
                return false
            end
        end
        return true
    end
    
    return false
end