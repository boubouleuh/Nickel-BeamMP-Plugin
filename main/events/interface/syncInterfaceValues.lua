local interfaceUtils = require("main.client.interfaceUtils")
local utils = require("utils.misc")
local syncinterfacevalues = {}
---@param managers managers
function syncinterfacevalues.new(managers)


    function SyncInterfaceValues(id, interfaceValues, force)
        print("jsonInterfaceValues", interfaceValues)
        local interfaceValues = Util.JsonDecode(interfaceValues)
        print("TableInterfaceValues", interfaceValues)

        if force == nil then
            force = false
        end
        if interfaceValues == nil then
            utils.nkprint("INTERFACE VALUES IS NIL", "error")
            return
        end
        local server_interface_values = managers.cfgManager:GetSetting("client").interfaceValues

        if not utils.deepCompare(interfaceValues, server_interface_values) or force then

            if not managers.permManager:hasPermissionForAction(utils.getPlayerBeamMPID(MP.GetPlayerName(id)), "editInterfaceSettings") then
                interfaceUtils.sendTable(id, "getInterfaceValues", server_interface_values)
                return
            end

            managers.cfgManager:SetSetting("client.interfaceValues", interfaceValues)

            interfaceUtils.sendTable(-1, "getInterfaceValues", interfaceValues)
            return
        end
    end
    MP.RegisterEvent("SyncInterfaceValues", "SyncInterfaceValues")

end



return syncinterfacevalues