local online = require("main.online")
local utils = require("utils.misc")
return function(player_id, vehicle_id, managers)

    local webhook = managers.cfgManager:GetSetting("discord").vehicle_webhook
    if webhook and webhook ~= "" then
        local username = "Nickel Vehicle Logger"
        local avatar = "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"


        local embedDescription = "**Edited car " .. vehicle_id .. "**"
        local color = 0x00FF00
        local name = MP.GetPlayerName(player_id) or "Unknown Player"
        online.sendDiscordMessage(
            webhook,
            "",                     
            username,
            avatar,
            "Edit",
            embedDescription,
            color,
            name,
            "",
            "https://forum.beammp.com/user_avatar/forum.beammp.com/"..name.."/120/58506_2.png",
            "Nickel",
            "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"
            
        )

    end
end