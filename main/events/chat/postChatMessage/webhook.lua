
return Event(function(NotRejected, id, name, message)

    local webhook = ConfigManager.GetSetting("discord").chat_webhook
    if webhook and webhook ~= "" then
        local username = "Nickel Chat Logger"
        local avatar = "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"


        local embedDescription = "**" .. message .. "**"
        local color = NotRejected and 0x00FF00 or 0xFF0000

        Online.sendDiscordMessage(
            webhook,
            "",                     
            username,
            avatar,
            "",
            embedDescription,
            color,
            name,
            "",
            "https://forum.beammp.com/user_avatar/forum.beammp.com/"..name.."/120/58506_2.png",
            "Nickel",
            "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"
            
        )

    end
end)