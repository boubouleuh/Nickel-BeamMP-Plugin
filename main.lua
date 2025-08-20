
function init()



    local initializeModules = require("main.initializeModules")




    local utils = require("utils.misc")

    --create reloader.lua if not exist
    local reloaderPath = utils.script_path() .. "reloader.lua"
    if not FS.Exists(reloaderPath) then
        local file = io.open(reloaderPath, "w")
        file:write("return " .. tostring(math.random(1, 1000000)))
        file:close()
        utils.nkprint("Created reloader.lua for manual hot-reload", "info")
    end

    local rootDirectory = utils.script_path()
    package.path = rootDirectory .. "objects/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "?.lua"
    if MP.GetOSName() == "Windows" then
        package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.4/?.dll"
        package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.3/?.dll"
    else
        package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.3/?.so"
        package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.4/?.so"
    end

    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/socket/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/ssl/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/socket/?.lua"
    package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/ssl/?.lua"
    initializeModules.initialize() 



    local config = require("main.config.Settings")

    ---@type Settings
    local cfgManager = config.init()

    local updater = require("main.updater")

    updater.check(cfgManager)


    -- Démarrer la traversée à partir du répertoire racine de votre projet
    --Objects used to make the tables
    local UserIp = require("objects.UserIp")
    local UserStatus = require("objects.UserStatus")
    local User = require("objects.User")
    local UserRole = require("objects.UserRole")
    local Role = require("objects.Role")
    local RoleCommand = require("objects.RoleCommand")
    local Command = require("objects.Command")
    local Action = require("objects.Action")
    local RoleAction = require("objects.RoleAction")
    local Infos = require("objects.Infos")

    local dispatcher = require("main.events.dispatcher")


    -- Events / Database / Events handler
    local databaseManager = require("database.Database")
    local messageHandlerManager = require("main.messages.MessagesHandler")
    local PermissionsHandler = require("main.permissions.PermissionsHandler")
    local commandHandler = require("main.commands.CommandsHandler")
    local actionHandler = require("main.actions.ActionsHandler")
    local default = require("main.permissions.default")
    -- local search = require("main.events.interface.search")
    -- Miscellanous



    if utils.getBeamMPConfig().General.LogChat and cfgManager:GetSetting("misc").chat_log then
        utils.nkprint("Chat logging is enabled in the Nickel config, but also in the BeamMP config. Please disable one of them to avoid duplicate logs.", "warn")
    end



    ---@type DatabaseManager
    local dbManager
    local syncConfig = cfgManager:GetSetting("sync")
    
    -- Create database configuration with both old and new settings
    local dbConfig = {
        database_type = syncConfig.database_type or "sqlite",
        database_file = syncConfig.database_file,
        mysql_host = syncConfig.mysql_host,
        mysql_port = syncConfig.mysql_port,
        mysql_database = syncConfig.mysql_database,
        mysql_username = syncConfig.mysql_username,
        mysql_password = syncConfig.mysql_password
    }
    
    -- Use default SQLite path if no database file is specified
    if (not dbConfig.database_file or dbConfig.database_file == "") and dbConfig.database_type == "sqlite" then
        utils.nkprint("No database file set in config, using default SQLite path", "info")
        dbConfig.database_file = utils.script_path() .. "database/db.sqlite"
    end

    -- Create database manager with new configuration
    dbManager = databaseManager.new(dbConfig)

    dbManager:withConnection(function()
        -- Apply database-specific optimizations
        if dbConfig.database_type == "sqlite" then
            dbManager.db:exec("PRAGMA journal_mode=WAL2;")
        end
        -- MySQL doesn't need PRAGMA statements
    end)

    ---@type MessagesHandler
    local msgManager = messageHandlerManager.new(dbManager,cfgManager)

    ---@type PermissionsHandler
    local permManager = PermissionsHandler.new(dbManager)

    dbManager:withConnection(function()
        -- Creating tables / updating
        dbManager:createTableForClass(User.new())
        dbManager:createTableForClass(UserIp.new())
        dbManager:createTableForClass(UserStatus.new())
        dbManager:createTableForClass(Role.new())
        dbManager:createTableForClass(Command.new())
        dbManager:createTableForClass(UserRole.new())
        dbManager:createTableForClass(Action.new())
        dbManager:createTableForClass(RoleAction.new())
        dbManager:createTableForClass(RoleCommand.new())
        dbManager:createTableForClass(Infos.new())
    end)




    ---@class managers
    local managers = {
        dbManager = dbManager,
        cfgManager = cfgManager,
        msgManager = msgManager,
        permManager = permManager,
    }
    local cmdManager = commandHandler.init(managers)
    local actManager = actionHandler.init(managers)
    managers.actManager = actManager
    managers.cmdManager = cmdManager



    dbManager:withConnection(function()

    local entry = dbManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch")
    if entry == nil then
        dbManager:save(Infos.new("isInitialDatabaseLaunch", "false"), true)
    elseif entry.infoValue == "false" then

        local class = Infos.new("isInitialDatabaseLaunch", "true")

        dbManager:save(class, true)

    end

    dbManager:save(Infos.new("version", updater.get_git_version()), true) --set version
    end)
    default.init(managers)

    -- Init Events
    dispatcher.load("init", managers)
    dispatcher.load("players", managers)
    dispatcher.load("chat", managers)
    dispatcher.load("console", managers)
    dispatcher.load("vehicles", managers)

    if cfgManager:GetSetting("client").interface then
        dispatcher.load("interface", managers)
        -- search.new(managers)
    end

    utils.nkprint("Nickel successfully initialized", "info")
    local extensions = require("main.initializeExtensions")
    extensions.initialize(managers)
    utils.nkprint("Extensions successfully initialized", "info")
end
MP.RegisterEvent("onInit", "init")
