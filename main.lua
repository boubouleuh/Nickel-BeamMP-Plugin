

local userIps = require("objects.UserIps")
local UserStatus = require("objects.UserStatus")
local user = require("objects.User")
local onPlayerAuth = require("main.events.register.onPlayerAuth")
local onChatMessage = require("main.events.chat.onChatMessage")
local databaseManager = require("database.Database")
local messageHandlerManager = require("main.messages.MessagesHandler")


local config = require("main.config.Settings")
local utils = require("utils.misc")

local dbManager = databaseManager.new(utils.script_path() .. "database/db.sqlite")

local cfgManager = config.init()

local msgManager = messageHandlerManager.new(dbManager,cfgManager)


-- Init class
dbManager:createTableForClass(user)
dbManager:createTableForClass(userIps)
dbManager:createTableForClass(UserStatus)
-- Init Events
onPlayerAuth.new(dbManager)

onChatMessage.new(msgManager)

