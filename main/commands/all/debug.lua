local command = RegisterCommand("debug")
command.consoleOnly = true
--- command
function command.init(sender_id, sender_name, field)
    if field == "events" then
        Nickel.ListEvents()
    elseif field == "globals" then
        Nickel.ListGlobals()
    elseif field == "error" then
        error("Debug error")
    end

    return true
end