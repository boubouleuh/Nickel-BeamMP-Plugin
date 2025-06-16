

local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local securevalues = {}
---@param managers managers
function securevalues.new(managers) -- this function is used to be sure that the client and the server have the same values for the interface

    
    function SecureValues()

        local server_interface_values = managers.cfgManager:GetSetting("client").interfaceValues
        interfaceUtils.sendTableToAll("getInterfaceValues", server_interface_values)

        local server_env = managers.cfgManager:GetSetting("client").environment

        interfaceUtils.sendTableToAll("receiveEnvironment", server_env)

    end
    MP.RegisterEvent("SecureValues", "SecureValues")
    MP.CreateEventTimer("SecureValues", 10000)
end




return securevalues