local userIps = require("objects.UserIps")
local UserStatus = require("objects.UserStatus")
local user = require("objects.User")
local onPlayerAuth = require("main.events.onPlayerAuth")
local databaseManager = require("database.Database")
local utils = require("utils.misc")


local dbManager = databaseManager.new(utils.script_path() .. "/database/db.sqlite")


-- Init class
dbManager:createTableForClass(user)
dbManager:createTableForClass(userIps)
dbManager:createTableForClass(UserStatus)
-- Init Events
onPlayerAuth.new(dbManager)


