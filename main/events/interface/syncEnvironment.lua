

local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local init = {}
---@param managers managers
function init.new(managers)

    
    function SyncEnvironment(id, environment, force)
        local environment = Util.JsonDecode(environment)

        if force == nil then
            force = false
        end
        if environment == nil then
            utils.nkprint("ENVIRONMENT IS NIL", "error")
            return
        end
        local server_env = managers.cfgManager:GetSetting("client")

        if not utils.deepCompare(environment, server_env) or force then


            if managers.permManager:hasPermissionForAction(utils.getPlayerBeamMPID(MP.GetPlayerName(id)), "editEnvironment") == false then

                interfaceUtils.sendTable(id, "receiveEnvironment", server_env)
                MP.Sleep(200) --need to see if it lags the server
                interfaceUtils.sendString(id, "clientSyncEnvironment", "")

                return
            end
     
            managers.cfgManager:SetSetting("client", environment)
    
            interfaceUtils.sendTable(-1, "receiveEnvironment", environment)
            MP.Sleep(200) --need to see if it lags the server
            interfaceUtils.sendString(-1, "clientSyncEnvironment", "")



            return
        end


       
      
    end
    MP.RegisterEvent("SyncEnvironment", "SyncEnvironment")

end




return init