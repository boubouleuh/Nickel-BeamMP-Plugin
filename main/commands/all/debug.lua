
local command = {
    type = "console",
}

--- command
function command.init(sender_id, sender_name, field)
    if field == "events" then
        Nickel.ListEvents()
    end

    return true
end

RegisterNickelCommand("debug", command)