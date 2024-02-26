
local utils = require("utils.misc")
local rootDirectory = utils.script_path()

print(package.path .. ";" .. rootDirectory  .. "?.lua")
package.path = package.path .. ";" .. rootDirectory  .. "?.lua"

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
--

-- Events / Database / Events handler
local onPlayerAuth = require("main.events.register.onPlayerAuth")
local onChatMessage = require("main.events.chat.onChatMessage")
local databaseManager = require("database.Database")
local messageHandlerManager = require("main.messages.MessagesHandler")
local commandHandler = require("main.commands.CommandsHandler")
local default = require("main.permissions.default")


-- Miscellanous
local config = require("main.config.Settings")

-- coucou
-- Instances

local dbManager = databaseManager.new(utils.script_path() .. "database/db.sqlite") --Keep the connection

dbManager:openConnection()

local cfgManager = config.init()

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
onPlayerAuth.new(permManager)

onChatMessage.new(cmdManager)
onConsoleInput.new(cmdManager)


