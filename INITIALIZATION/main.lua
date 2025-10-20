if Utils.getBeamMPConfig() and Utils.getBeamMPConfig().General.LogChat and ConfigManager.GetSetting("misc").chat_log then
    Utils.nkprint("Chat logging is enabled in the Nickel config, but also in the BeamMP config. Please disable one of them to avoid duplicate logs.", "warn")
end

-- Create all database tables
Utils.nkprint("Creating database tables...", "info")
DatabaseManager:withConnection(function()
    -- Simple table creation using getColumns functions directly
    DatabaseManager:createTableIfNotExists(User.tableName, User.getColumns())
    DatabaseManager:createTableIfNotExists(UserIp.tableName, UserIp.getColumns())
    DatabaseManager:createTableIfNotExists(UserStatus.tableName, UserStatus.getColumns())
    DatabaseManager:createTableIfNotExists(Role.tableName, Role.getColumns())
    DatabaseManager:createTableIfNotExists(Command.tableName, Command.getColumns())
    DatabaseManager:createTableIfNotExists(UserRole.tableName, UserRole.getColumns())
    DatabaseManager:createTableIfNotExists(Action.tableName, Action.getColumns())
    DatabaseManager:createTableIfNotExists(RoleAction.tableName, RoleAction.getColumns())
    DatabaseManager:createTableIfNotExists(RoleCommand.tableName, RoleCommand.getColumns())
    DatabaseManager:createTableIfNotExists(Infos.tableName, Infos.getColumns())
end)

-- Initialize info entry for database launch
DatabaseManager:withConnection(function()
    local entry = DatabaseManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch")
    if entry == nil then
        DatabaseManager:save(Infos.new("isInitialDatabaseLaunch", "false"), true)
    elseif entry.infoValue == "false" then
        local class = Infos.new("isInitialDatabaseLaunch", "true")
        DatabaseManager:save(class, true)
    end
end)

Utils.nkprint("Nickel basic initialization complete", "info")

-- Initialize handlers and make them global
Utils.nkprint("Initializing handlers...", "info")

ActionsManager.init()
CommandsManager.init()


Utils.nkprint("All handlers and services initialized successfully", "info")


DefaultPermissions.init()

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