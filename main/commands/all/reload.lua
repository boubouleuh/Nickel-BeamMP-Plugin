local command = RegisterCommand("reload", {
    type = "console",
})

--- command
function command.init(sender_id, sender_name)
    Nickel.Reload()

    return true
end