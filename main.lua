
function init()
    local initializeModules = require("main.initializeModules")




    local utils = require("utils.misc")

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







    ---@type DatabaseManager
    local dbManager
    local configDatabaseFile = cfgManager:GetSetting("sync").database_file

    if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
        dbManager = databaseManager.new(configDatabaseFile) --Keep the connection
    else
        utils.nkprint("No database set in config, now using default path", "info")
        dbManager = databaseManager.new(utils.script_path() .. "database/db.sqlite") --Keep the connection
    end

    dbManager:withConnection(function()
        dbManager.db:exec("PRAGMA journal_mode=WAL2;")
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

    if cfgManager:GetSetting("client").interface then
        dispatcher.load("vehicles", managers)
        dispatcher.load("interface", managers)
        -- search.new(managers)
    end

    utils.nkprint("Nickel successfully initialized", "info")
    local extensions = require("main.initializeExtensions")
    extensions.initialize(managers)
    utils.nkprint("Extensions successfully initialized", "info")
end
MP.RegisterEvent("onInit", "init")
