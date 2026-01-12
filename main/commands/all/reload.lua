local command = RegisterCommand("reload")
command.consoleOnly = true

--- command
function command.init(sender_id, sender_name)
    Nickel.Reload()

    return true
end