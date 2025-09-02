
return function(player_id, vehicle_id, data)
    local environment = ConfigManager.GetSetting("client").environment
    if environment then
        MP.TriggerLocalEvent("SyncEnvironment", player_id, Util.JsonEncode(environment), true)
    end
end