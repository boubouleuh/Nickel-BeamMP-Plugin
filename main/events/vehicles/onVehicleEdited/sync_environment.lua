
return function(player_id, vehicle_id, data, managers)
    MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(managers.cfgManager:GetSetting("client").environment), true)
end