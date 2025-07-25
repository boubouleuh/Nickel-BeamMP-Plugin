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


end