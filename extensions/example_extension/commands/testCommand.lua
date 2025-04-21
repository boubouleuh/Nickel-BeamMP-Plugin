
local utils = require("utils.misc")

local command = {}

function command.init(sender_id, sender_name, managers, playername, reason) --add parameters here
    local permManager = managers.permManager
    local msgManager = managers.msgManager      --Yes here you have access to everything, there will be a documentation maybe..
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager

    msgManager:SendMessage(sender_id, "the test is successfull")
    --msgManager:SendMessage(sender_id, "commands.ban.missing_args", cfgManager.config.commands.prefix) you can also do things like that to translate things

    return true --if the command is successfull otherwise you will need to return false !
end

return command