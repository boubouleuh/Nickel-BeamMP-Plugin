
local utils = require("utils.misc")
local UsersService = require("database.services.UsersService")
local command = {
    --TODO need type user but the command layout doesnt support it yet, need to think about a better way to handle args for the interface
    args = {
        {name = "addORremove", type = "string"},
        {name = "playername", type = "string"}
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, addORremove, playername)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager


    if playername == nil or not utils.element_exist_in_table(addORremove, {"add", "remove"}) then
        msgManager:SendMessage(sender_id, "commands.whitelist.missing_args", {Prefix = cfgManager.config.commands.prefix})
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
        msgManager:SendMessage(sender_id, "commands.whitelist.add.success", {Player = playername})
    elseif addORremove == "remove" then
        usersService:setWhitelisted(false)
        msgManager:SendMessage(sender_id, "commands.whitelist.remove.success", {Player = playername})
    end
    



    return true
end

return command