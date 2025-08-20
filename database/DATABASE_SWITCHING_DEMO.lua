-- Database Switching Demo
-- This file demonstrates how to configure different database types

-- Example NickelConfig.toml configurations:

--[[
SQLite Configuration (Default):
[sync]
database_file = "database/nickel.sqlite"
database_type = "sqlite"

MySQL Configuration:
[sync]
database_type = "mysql"
mysql_host = "localhost"
mysql_port = 3306
mysql_database = "nickel_beammp"
mysql_username = "nickel_user"
mysql_password = "secure_password"
database_file = ""  # Not used for MySQL

Mixed Example (switching databases):
[sync]
database_type = "sqlite"  # Change to "mysql" to switch
database_file = "database/nickel.sqlite"
mysql_host = "localhost"
mysql_port = 3306
mysql_database = "nickel_beammp"
mysql_username = "nickel_user"
mysql_password = "secure_password"
--]]

-- Code usage remains the same regardless of database type:
--[[
local databaseManager = require("database.Database")
local config = require("main.config.Settings")

local cfgManager = config.init()
local syncConfig = cfgManager:GetSetting("sync")

-- The database manager automatically selects the right adapter
local dbManager = databaseManager.new(syncConfig)

-- All existing operations work the same way:
dbManager:withConnection(function()
    dbManager:createTableForClass(User.new())
    -- ... other operations
end)
--]]

print("Database switching demo - check comments for configuration examples")