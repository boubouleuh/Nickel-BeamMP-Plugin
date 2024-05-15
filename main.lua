


local initializeModules = require("main.initializeModules")





local utils = require("utils.misc")
local rootDirectory = utils.script_path()
package.path = rootDirectory .. "objects/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "?.lua"
package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.3/?.so"
package.cpath = package.cpath .. ";" .. rootDirectory  .. "lib/lua/5.4/?.so"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/socket/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.4/ssl/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/socket/?.lua"
package.path = package.path .. ";" .. rootDirectory  .. "share/lua/5.3/ssl/?.lua"
initializeModules.initialize()


-- Démarrer la traversée à partir du répertoire racine de votre projet
--Objects used to make the tables
local UserIps = require("objects.UserIps")
local UserStatus = require("objects.UserStatus")
local User = require("objects.User")
local UserRole = require("objects.UserRole")
local Role = require("objects.Role")
local RoleCommand = require("objects.RoleCommand")
local Command = require("objects.Command")
local onConsoleInput = require("main.events.console.onConsoleInput")


-- Events / Database / Events handler
local onPlayerAuth = require("main.events.register.onPlayerAuth")
local onChatMessage = require("main.events.chat.onChatMessage")
local databaseManager = require("database.Database")
local messageHandlerManager = require("main.messages.MessagesHandler")
local commandHandler = require("main.commands.CommandsHandler")
local default = require("main.permissions.default")


-- Miscellanous
local config = require("main.config.Settings")
local utils = require("utils.misc")


-- Instances
local cfgManager = config.init()

local dbManager
local configDatabaseFile = cfgManager:GetSetting("sync").database_file
print("config", configDatabaseFile)
if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
    dbManager = databaseManager.new(configDatabaseFile) --Keep the connection
else
    print("No db in config")
    dbManager = databaseManager.new(utils.script_path() .. "database/db.sqlite") --Keep the connection
end


dbManager:openConnection()


local msgManager = messageHandlerManager.new(dbManager,cfgManager)

local permManager = PermissionsHandler.new(dbManager)

-- Creating tables / updating
dbManager:createTableForClass(User)
dbManager:createTableForClass(UserIps)
dbManager:createTableForClass(UserStatus)

dbManager:createTableForClass(Role)
dbManager:createTableForClass(Command)
dbManager:createTableForClass(UserRole)
dbManager:createTableForClass(RoleCommand)

dbManager:closeConnection()


local managers = {
    dbManager = dbManager,
    cfgManager = cfgManager,
    msgManager = msgManager,
    permManager = permManager
}

local cmdManager = commandHandler.init(managers)

default.init(permManager)

-- Init Events
onPlayerAuth.new(permManager, msgManager)

onChatMessage.new(cmdManager)
onConsoleInput.new(cmdManager)


