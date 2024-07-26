
local utils = require("utils.misc")
local UsersService = require("database.services.UsersService")
local command = {}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, addORremove, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager


    if playername == nil or not utils.element_exist_in_table(addORremove, {"add", "remove"}) then
        msgManager:SendMessage(sender_id, "commands.whitelist.missing_args", cfgManager.config.commands.prefix)
        return false
    end

    if MP.IsPlayerGuest(utils.GetPlayerId(playername)) then
        msgManager:SendMessage(sender_id, "commands.guest_not_compatible")
        return false
    end
    local beammpid = utils.getPlayerBeamMPID(playername)

    local usersService = UsersService.new(beammpid, dbManager)


    if addORremove == "add" then
        usersService:setWhitelisted(true)
        msgManager:SendMessage(sender_id, "commands.whitelist.add.success", playername)
    elseif addORremove == "remove" then
        usersService:setWhitelisted(false)
        msgManager:SendMessage(sender_id, "commands.whitelist.remove.success", playername)
    end
    



    return true
end

return command