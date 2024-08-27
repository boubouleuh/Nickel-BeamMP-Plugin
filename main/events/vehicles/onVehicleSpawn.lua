
local onVehicleSpawn = {}
function onVehicleSpawn.new(managers)
    
    

    function onSpawn(player_id, vehicle_id, data)
        MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(managers.cfgManager:GetSetting("client")), true)
    end

    MP.RegisterEvent("onVehicleSpawn", "onSpawn")

end




return onVehicleSpawn