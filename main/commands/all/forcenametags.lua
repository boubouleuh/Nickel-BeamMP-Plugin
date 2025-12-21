
local command = RegisterCommand("forcenametags", {
    type = "global",
    args = {}
})

--- command
function command.init(sender_id, sender_name)
    if sender_id == -2 then
        return false
    end

    local beammpid = Utils.getPlayerBeamMPID(sender_name)
    if not beammpid then
        MessagesManager:SendMessage(sender_id, "player.not_found", {Player = sender_name})
        return false
    end

    local currentValue = SessionManager.getData(beammpid, "bypassNametags")


    -- Basculer entre on/off
    if currentValue == nil or currentValue == "off" then
        SessionManager.set(beammpid, "bypassNametags", "on")    --todo switch to : SessionManager.toggle(beammpid, "bypassNametags")
        currentValue = "on"
    else
        SessionManager.set(beammpid, "bypassNametags", "off")
        currentValue = "off"
    end

    -- Envoyer la nouvelle valeur au client
    MP.TriggerClientEventJson(sender_id, "setNickelValue", string.format('{"key": "bypassNametags", "value": "%s"}', currentValue))
    
    MessagesManager:SendMessage(sender_id, "commands.nametags.success", {
        Prefix = ConfigManager.GetSetting("commands").prefix,
        On_Off = currentValue
    })
    
    return true
end