
local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
---@param managers managers
return function(managers)

    local server_interface_values = managers.cfgManager:GetSetting("client").interfaceValues
    interfaceUtils.sendTableToAll("getInterfaceValues", server_interface_values)

    local server_env = managers.cfgManager:GetSetting("client").environment

    interfaceUtils.sendTableToAll("receiveEnvironment", server_env)

end

