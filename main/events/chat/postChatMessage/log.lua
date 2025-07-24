local utils = require("utils.misc")
local online = require("main.online")
return function(NotRejected, id, name, message, managers)
    local log;
    if not NotRejected then
        log = utils.print_color("[NICKEL", "gray") .. utils.print_color("|CHAT] ", "green") .. utils.print_color(id .. "|" .. name .. " > tried to say", "red") .. " : " .. message .. utils.print_color(" | but was rejected", "red")
    else
        log = utils.print_color("[NICKEL", "gray") .. utils.print_color("|CHAT] ", "green") .. utils.print_color(id .. "|" .. name, "yellow") .. " : " .. message
    end
    if managers.cfgManager:GetSetting("misc").chat_log then
        print(log)
    end
    local webhook = managers.cfgManager:GetSetting("discord").chat_webhook
    if webhook and webhook ~= "" then
        local username = "Nickel Chat Logger"
        local avatar = "https://cdn.discordapp.com/icons/1073280205826826261/377e11e72cf395b7dcacda78621e473e.png?size=512"


        local embedDescription = "**" .. message .. "**"
        local color = NotRejected and 0x00FF00 or 0xFF0000

        online.sendDiscordMessage(
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

end