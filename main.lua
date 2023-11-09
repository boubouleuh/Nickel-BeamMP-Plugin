local user = require("objects.User")
local onPlayerAuth = require("main.events.onPlayerAuth")
local databaseManager = require("database.Database")
local utils = require("utils.misc")






local dbManager = databaseManager.new(utils.script_path() .. "/database/db.sqlite")


dbManager:createTableForClass(user)

onPlayerAuth.new(dbManager)


