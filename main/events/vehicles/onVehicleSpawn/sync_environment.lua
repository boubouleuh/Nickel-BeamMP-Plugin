
return Event(function(player_id, vehicle_id, data)
    local environment = ConfigManager.GetSetting("client").environment
    MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(environment), true)
    
end):If(ConfigManager.GetSetting("client").environment)