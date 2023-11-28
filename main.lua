--Objects used to make the tables

local UserIps = require("objects.UserIps")
local UserStatus = require("objects.UserStatus")
local User = require("objects.User")
local UserRole = require("objects.UserRole")
local Role = require("objects.Role")
local RoleCommand = require("objects.RoleCommand")
local Command = require("objects.Command")


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

local cfgManager = config.init()

local msgManager = messageHandlerManager.new(dbManager,cfgManager)

-- Creating tables / updating
dbManager:createTableForClass(User)
dbManager:createTableForClass(UserIps)
dbManager:createTableForClass(UserStatus)

dbManager:createTableForClass(Role)
dbManager:createTableForClass(Command)
dbManager:createTableForClass(UserRole)
dbManager:createTableForClass(RoleCommand)

defaultRoles.init(dbManager)

local cmdManager = commandHandler.init(msgManager)



-- Init Events
onPlayerAuth.new(dbManager)

onChatMessage.new(cmdManager)

