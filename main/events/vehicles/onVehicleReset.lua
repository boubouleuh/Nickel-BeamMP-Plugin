
local onVehicleReset = {}
function onVehicleReset.new(managers)


    function onReset(player_id, vehicle_id, data)
        MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(managers.cfgManager:GetSetting("client")), true)
    end

    MP.RegisterEvent("onVehicleReset", "onReset")

end




return onVehicleReset