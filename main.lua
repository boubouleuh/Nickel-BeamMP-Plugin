

local initializeModules = require("main.initializeModules")


local infos = require("infos.infos")



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
local Infos = require("objects.Infos")
local onConsoleInput = require("main.events.console.onConsoleInput")


-- Events / Database / Events handler
local initInterface = require("main.events.interface.init")
local onPlayerAuth = require("main.events.register.onPlayerAuth")
local onChatMessage = require("main.events.chat.onChatMessage")
local databaseManager = require("database.Database")
local messageHandlerManager = require("main.messages.MessagesHandler")
local commandHandler = require("main.commands.CommandsHandler")
local default = require("main.permissions.default")


-- Miscellanous
local config = require("main.config.Settings")


-- Instances
---@type Settings
local cfgManager = config.init()

---@type DatabaseManager
local dbManager
local configDatabaseFile = cfgManager:GetSetting("sync").database_file

if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
    dbManager = databaseManager.new(configDatabaseFile) --Keep the connection
else
    utils.nkprint("No database set in config, now using default path", "info")
    dbManager = databaseManager.new(utils.script_path() .. "database/db.sqlite") --Keep the connection
end


dbManager:openConnection()

---@type MessagesHandler
local msgManager = messageHandlerManager.new(dbManager,cfgManager)

---@type PermissionsHandler
local permManager = PermissionsHandler.new(dbManager)

-- Creating tables / updating
dbManager:createTableForClass(User.new())
dbManager:createTableForClass(UserIps.new())
dbManager:createTableForClass(UserStatus.new())

dbManager:createTableForClass(Role.new())
dbManager:createTableForClass(Command.new())
dbManager:createTableForClass(UserRole.new())
dbManager:createTableForClass(RoleCommand.new())
dbManager:createTableForClass(Infos.new())

dbManager:closeConnection()

dbManager:openConnection()


local entry = dbManager:getEntry(Infos, "infoKey", "isInitialDatabaseLaunch")
if entry == nil then
    dbManager:save(Infos.new("isInitialDatabaseLaunch", "false"), true)
elseif entry.infoValue == "false" then

    local class = Infos.new("isInitialDatabaseLaunch", "true")


    dbManager:save(class, true)

end


dbManager:closeConnection()



---@class managers
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

initInterface.new(managers)

utils.nkprint("Plugin successfully initialized", "info")

local extensions = require("main.initializeExtensions")
extensions.initialize(managers)
utils.nkprint("Extensions initialized", "info")