
return Event(function(NotRejected, player_id, vehicle_id, data)

    local webhook = ConfigManager.GetSetting("discord").vehicle_webhook
    local username = "Nickel Vehicle Logger"
    local avatar = "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"

    local beammpid = Utils.getPlayerBeamMPID(player_id)
    local vehs = SessionManager.getData(beammpid, "vehicles", nil)
    local oldveh = Utils.parseBeamData(vehs[vehicle_id]).jbm
    local newveh = Utils.parseBeamData(data).jbm
    local embedDescription = ""
    if oldveh ~= newveh then
        embedDescription = "**Switched from " .. oldveh .. " to " .. newveh .. "**"
    else
        embedDescription = "**Edited " .. newveh .. "**"
    end
    local color = NotRejected and 0x00FF00 or 0xFF0000
    local name = MP.GetPlayerName(player_id) or "Unknown Player"
    Online.sendDiscordMessage(
        webhook,
        "",                     
        username,
        avatar,
        Utils.getMapName(),
        embedDescription,
        color,
        name,
        "",
        "https://forum.beammp.com/user_avatar/forum.beammp.com/"..name.."/120/58506_2.png",
        "Nickel",
        "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"
        
    )

end):Require(ConfigManager.GetSetting("discord").vehicle_webhook ~= "")