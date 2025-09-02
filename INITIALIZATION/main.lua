print("Initializing Nickel Plugin...")
print("Utils available:", Utils and "YES" or "NO")
print("Settings available:", Settings and "YES" or "NO")

-- Check BeamMP config vs Nickel config for chat logging
if Utils.getBeamMPConfig() and Utils.getBeamMPConfig().General.LogChat and Settings.GetSetting("misc").chat_log then
    Utils.nkprint("Chat logging is enabled in the Nickel config, but also in the BeamMP config. Please disable one of them to avoid duplicate logs.", "warn")
end

-- Initialize Database
local dbManager
local configDatabaseFile = Settings.GetSetting("sync").database_file

if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
    dbManager = DatabaseManager.new(configDatabaseFile)
    Utils.nkprint("Using custom database: " .. configDatabaseFile, "info")
else
    Utils.nkprint("No database set in config, now using default path", "info") 
    dbManager = DatabaseManager.new(Utils.script_path() .. "database/db.sqlite")
end

dbManager:withConnection(function()
    dbManager.db:exec("PRAGMA journal_mode=WAL2;")
end)

-- Create all database tables
Utils.nkprint("Creating database tables...", "info")
dbManager:withConnection(function()
    -- Simple table creation using getColumns functions directly
    dbManager:createTableIfNotExists(User.tableName, User.getColumns())
    dbManager:createTableIfNotExists(UserIp.tableName, UserIp.getColumns())
    dbManager:createTableIfNotExists(UserStatus.tableName, UserStatus.getColumns())
    dbManager:createTableIfNotExists(Role.tableName, Role.getColumns())
    dbManager:createTableIfNotExists(Command.tableName, Command.getColumns())
    dbManager:createTableIfNotExists(UserRole.tableName, UserRole.getColumns())
    dbManager:createTableIfNotExists(Action.tableName, Action.getColumns())
    dbManager:createTableIfNotExists(RoleAction.tableName, RoleAction.getColumns())
    dbManager:createTableIfNotExists(RoleCommand.tableName, RoleCommand.getColumns())
    dbManager:createTableIfNotExists(Infos.tableName, Infos.getColumns())
end)

-- Initialize info entry for database launch
dbManager:withConnection(function()
    local entry = dbManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch")
    if entry == nil then
        dbManager:save(Infos.new("isInitialDatabaseLaunch", "false"), true)
    elseif entry.infoValue == "false" then
        local class = Infos.new("isInitialDatabaseLaunch", "true")
        dbManager:save(class, true)
    end
    -- dbManager:save(Infos.new("version", "tree-framework-migration"), true)
end)

Utils.nkprint("Nickel basic initialization complete", "info")

-- Initialize handlers and make them global
Utils.nkprint("Initializing handlers...", "info")

DatabaseManager = dbManager
ConfigManager = Settings
MessagesManager = MessagesHandler.new()
PermissionsManager = PermissionsHandler.new()
CommandsHandler.init()
ActionsHandler.init()
CommandsManager = CommandsHandler
ActionsManager = ActionsHandler


Utils.nkprint("All handlers and services initialized successfully", "info")

-- Initialize event dispatcher
Utils.nkprint("Initializing event system...", "info")
if EventDispatcher and EventDispatcher.load then
    EventDispatcher.load("console")
    EventDispatcher.load("init")
    EventDispatcher.load("chat")
    EventDispatcher.load("players")
    EventDispatcher.load("interface")
    EventDispatcher.load("vehicles")
    Utils.nkprint("Event system fully initialized", "info")
end

Utils.nkprint("Nickel Plugin fully initialized!", "info")


