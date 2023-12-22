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
local defaultRoles = require("main.permissions.default")


-- Miscellanous
local config = require("main.config.Settings")
local utils = require("utils.misc")


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

defaultRoles.init(permManager)



local managers = {
    dbManager = dbManager,
    cfgManager = cfgManager,
    msgManager = msgManager,
    permManager = permManager
}

local cmdManager = commandHandler.init(managers)


-- Init Events
onPlayerAuth.new(permManager)

onChatMessage.new(cmdManager)
onConsoleInput.new(cmdManager)


