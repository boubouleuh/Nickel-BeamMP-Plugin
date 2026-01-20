return Event(function(player_id)
    local webhook = ConfigManager.GetSetting("discord").player_webhook
    local playerName = MP.GetPlayerName(player_id)
    local beammpid = Utils.getPlayerBeamMPID(playerName)
    
    if beammpid then
        local username = "Nickel Player Logger"
        local avatar = "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"

        local embedDescription = "**" .. playerName ..  " joined " .. Utils.getMapName() .. " **"
        local color = 0x00FF00
        
        Online.sendDiscordMessage(
            webhook,
            "",                     
            username,
            avatar,
            "",
            embedDescription,
            color,
            playerName,
            "",
            "https://forum.beammp.com/user_avatar/forum.beammp.com/"..playerName.."/120/58506_2.png",
            "Nickel",
            "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"
        )
    end
end):Require(ConfigManager.GetSetting("discord").player_webhook ~= "")