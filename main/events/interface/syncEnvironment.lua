

local interfaceUtils = require("main.client.interfaceUtils")

local init = {}
---@param managers managers
function init.new(managers)

    
    function SyncEnvironment(id, environment, istargetingId)
        if istargetingId == nil then
            istargetingId = false
        end

        if environment == nil then
            print("ENVIRONMENT IS NIL")
            return
        end
        local environment = Util.JsonDecode(environment)
  
        managers.cfgManager:SetSetting("client", environment)

        interfaceUtils.sendTable(istargetingId and id or -1, "receiveEnvironment", environment)
        MP.Sleep(200) --need to see if it lags the server
        print("SyncEnvironment sent")
        interfaceUtils.sendString(istargetingId and id or -1, "clientSyncEnvironment", "")
    end
    MP.RegisterEvent("SyncEnvironment", "SyncEnvironment")

end




return init