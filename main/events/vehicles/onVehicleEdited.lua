
local onVehicleEdited = {}
function onVehicleEdited.new(managers)
    
    
    function onEdited(player_id, vehicle_id, data)
        MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(managers.cfgManager:GetSetting("client")), true)
    end

    MP.RegisterEvent("onVehicleEdited", "onEdited")

end


return onVehicleEdited