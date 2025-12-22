if Utils.getBeamMPConfig() and Utils.getBeamMPConfig().General.LogChat and ConfigManager.GetSetting("misc").chat_log then
    Utils.nkprint("Chat logging is enabled in the Nickel config, but also in the BeamMP config. Please disable one of them to avoid duplicate logs.", "warn")
end

-- Create all database tables
Utils.nkprint("Creating database tables...", "info")
DatabaseManager:withConnection(function()
    -- Simple table creation using getColumns functions directly
    DatabaseManager:createTableForClass(User, false)
    DatabaseManager:createTableForClass(UserIp, false)
    DatabaseManager:createTableForClass(UserStatus, false)
    DatabaseManager:createTableForClass(Role, false)
    DatabaseManager:createTableForClass(Command, false)
    DatabaseManager:createTableForClass(UserRole, false)
    DatabaseManager:createTableForClass(Action, false)
    DatabaseManager:createTableForClass(RoleAction, false)
    DatabaseManager:createTableForClass(RoleCommand, false)
    DatabaseManager:createTableForClass(Infos, false)
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