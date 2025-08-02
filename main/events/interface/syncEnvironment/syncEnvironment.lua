

local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local syncenvironment = {}
---@param managers managers
return function(id, environment, managers, force)
    local environment = Util.JsonDecode(environment)

    if force == nil then
        force = false
    end
    if environment == nil then
        utils.nkprint("ENVIRONMENT IS NIL", "error")
        return
    end
    local server_env = managers.cfgManager:GetSetting("client").environment

    if not utils.deepCompare(environment, server_env) or force then


        if not managers.permManager:hasPermissionForAction(utils.getPlayerBeamMPID(MP.GetPlayerName(id)), "editEnvironment") then
            interfaceUtils.sendTable(id, "receiveEnvironment", server_env)

            return
        end
    
        managers.cfgManager:SetSetting("client.environment", environment)

        interfaceUtils.sendTableToAll("receiveEnvironment", environment)

        return
    end
end

