
return Event(function(player_id, vehicle_id, data, managers)
    MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(ConfigManager.GetSetting("client").environment), true)
end)