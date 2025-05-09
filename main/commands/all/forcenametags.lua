
local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local Role = require("objects.Role")
local sessionPlayerStorage = require("main.sessionPlayerStorage")
local command = {
    type="global",
    args = {
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers)
    ---@type PermissionsHandler
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    ---@type DatabaseManager
    local dbManager = managers.dbManager

    if sender_id == -2 then
        return false
    end

    local sessionStorage = sessionPlayerStorage:new(utils.getPlayerBeamMPID(sender_name))
    local currentValue = sessionStorage:get("bypassNametags")
    if currentValue == nil or currentValue == "off" then
        sessionStorage:set("bypassNametags", "on")
    elseif currentValue == "on" then
        sessionStorage:set("bypassNametags", "off")
    end
    local currentValue = sessionStorage:get("bypassNametags")

    interfaceUtils.sendString(sender_id, "bypassNametags", currentValue)
    msgManager:SendMessage(sender_id, "commands.nametags.success", {Prefix = cfgManager.config.commands.prefix, On_Off = currentValue})
    return true

end

return command