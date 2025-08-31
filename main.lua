
local function init()
    -- Load all required modules
    local initializeModules = require("main.initializeModules")
    local utils = require("utils.misc")
    local config = require("main.config.Settings")
    local updater = require("main.updater")
    local dispatcher = require("main.events.dispatcher")
    local databaseManager = require("database.Database")
    local messageHandlerManager = require("main.messages.MessagesHandler")
    local PermissionsHandler = require("main.permissions.PermissionsHandler")
    local commandHandler = require("main.commands.CommandsHandler")
    local actionHandler = require("main.actions.ActionsHandler")
    local default = require("main.permissions.default")
    local extensions = require("main.initializeExtensions")

    local rootDirectory = utils.script_path()
    
    -- Create reloader file for hot-reload functionality
    local function createReloader()
        local reloaderPath = rootDirectory .. "reloader.lua"
        if FS.Exists(reloaderPath) then
            return
        end
        
        local file = io.open(reloaderPath, "w")
        if not file then
            return
        end
        
        file:write("return " .. tostring(math.random(1, 1000000)))
        file:close()
        utils.nkprint("Created reloader.lua for manual hot-reload", "info")
    end

    -- Setup Lua package paths for modules and libraries
    local function setupPackagePaths()
        package.path = rootDirectory .. "objects/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "?.lua"
        
        -- Add platform-specific library paths
        if MP.GetOSName() == "Windows" then
            package.cpath = package.cpath .. ";" .. rootDirectory .. "lib/lua/5.4/?.dll"
            package.cpath = package.cpath .. ";" .. rootDirectory .. "lib/lua/5.3/?.dll"
        else
            package.cpath = package.cpath .. ";" .. rootDirectory .. "lib/lua/5.3/?.so"
        end
        
        -- Add shared library paths for socket and SSL
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.4/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.3/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.4/socket/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.4/ssl/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.3/socket/?.lua"
        package.path = package.path .. ";" .. rootDirectory .. "share/lua/5.3/ssl/?.lua"
    end

    -- Load all object classes used for database tables
    local function loadObjectClasses()
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
        
        return {
            UserIp = UserIp,
            UserStatus = UserStatus,
            User = User,
            UserRole = UserRole,
            Role = Role,
            RoleCommand = RoleCommand,
            Command = Command,
            Action = Action,
            RoleAction = RoleAction,
            Infos = Infos
        }
    end

    -- Check for chat logging conflicts between Nickel and BeamMP
    local function checkChatLoggingConflict(cfgManager)
        if not utils.getBeamMPConfig().General.LogChat then
            return
        end
        
        if not cfgManager:GetSetting("misc").chat_log then
            return
        end
        
        utils.nkprint("Chat logging is enabled in the Nickel config, but also in the BeamMP config. Please disable one of them to avoid duplicate logs.", "warn")
    end

    -- Initialize database connection and setup
    local function initializeDatabase(cfgManager)
        local configDatabaseFile = cfgManager:GetSetting("sync").database_file
        local dbManager
        
        if configDatabaseFile and configDatabaseFile ~= "" then
            dbManager = databaseManager.new(configDatabaseFile)
        else
            utils.nkprint("No database set in config, now using default path", "info")
            dbManager = databaseManager.new(rootDirectory .. "database/db.sqlite")
        end
        
        -- Enable WAL2 mode for better performance
        dbManager:withConnection(function()
            dbManager.db:exec("PRAGMA journal_mode=WAL2;")
        end)
        
        return dbManager
    end

    -- Create all database tables for the application
    local function createDatabaseTables(dbManager, objectClasses)
        dbManager:withConnection(function()
            dbManager:createTableForClass(objectClasses.User.new())
            dbManager:createTableForClass(objectClasses.UserIp.new())
            dbManager:createTableForClass(objectClasses.UserStatus.new())
            dbManager:createTableForClass(objectClasses.Role.new())
            dbManager:createTableForClass(objectClasses.Command.new())
            dbManager:createTableForClass(objectClasses.UserRole.new())
            dbManager:createTableForClass(objectClasses.Action.new())
            dbManager:createTableForClass(objectClasses.RoleAction.new())
            dbManager:createTableForClass(objectClasses.RoleCommand.new())
            dbManager:createTableForClass(objectClasses.Infos.new())
        end)
    end

    -- Initialize database with version and launch info
    local function initializeDatabaseInfo(dbManager, objectClasses, updater)
        dbManager:withConnection(function()
            local entry = dbManager:getEntry(objectClasses.Infos, "infoKey", "isInitialDatabaseLaunch")
            
            if not entry then
                dbManager:save(objectClasses.Infos.new("isInitialDatabaseLaunch", "false"), true)
            elseif entry.infoValue == "false" then
                local class = objectClasses.Infos.new("isInitialDatabaseLaunch", "true")
                dbManager:save(class, true)
            end
            
            dbManager:save(objectClasses.Infos.new("version", updater.get_git_version()), true)
        end)
    end

    -- Load all event dispatchers for different game events
    local function loadEventDispatchers(dispatcher, managers, cfgManager)
        dispatcher.load("init", managers)
        dispatcher.load("players", managers)
        dispatcher.load("chat", managers)
        dispatcher.load("console", managers)
        dispatcher.load("vehicles", managers)
        
        -- Load interface dispatcher if enabled
        if cfgManager:GetSetting("client").interface then
            dispatcher.load("interface", managers)
        end
    end

    -- Main initialization sequence
    createReloader()
    setupPackagePaths()
    initializeModules.initialize()
    
    local cfgManager = config.init()
    updater.check(cfgManager)
    
    local objectClasses = loadObjectClasses()
    checkChatLoggingConflict(cfgManager)
    
    local dbManager = initializeDatabase(cfgManager)
    local msgManager = messageHandlerManager.new(dbManager, cfgManager)
    local permManager = PermissionsHandler.new(dbManager)
    
    createDatabaseTables(dbManager, objectClasses)
    
    -- Create managers table for dependency injection
    local managers = {
        dbManager = dbManager,
        cfgManager = cfgManager,
        msgManager = msgManager,
        permManager = permManager
    }
    
    local cmdManager = commandHandler.init(managers)
    local actManager = actionHandler.init(managers)
    managers.actManager = actManager
    managers.cmdManager = cmdManager
    
    initializeDatabaseInfo(dbManager, objectClasses, updater)
    default.init(managers)
    
    loadEventDispatchers(dispatcher, managers, cfgManager)
    
    utils.nkprint("Nickel successfully initialized", "info")
    extensions.initialize(managers)
    utils.nkprint("Extensions successfully initialized", "info")
end

-- Register the init function to be called when the server starts
MP.RegisterEvent("onInit", "init")
