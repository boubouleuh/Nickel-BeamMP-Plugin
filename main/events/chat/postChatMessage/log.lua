return Event(function(NotRejected, id, name, message)
    local log
    if not NotRejected then
        log = Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|CHAT] ", "green") .. Utils.print_color(id .. "|" .. name .. " > tried to say", "red") .. " : " .. message .. Utils.print_color(" | but was rejected", "red")
    else
        log = Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|CHAT] ", "green") .. Utils.print_color(id .. "|" .. name, "yellow") .. " : " .. message
    end
    
    if ConfigManager.GetSetting("misc").chat_log then
        print(log)
    end
end)