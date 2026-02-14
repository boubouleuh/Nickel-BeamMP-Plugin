
local command = RegisterCommand("forceupdate")
command.consoleOnly = true
--- command
function command.init(sender_id, sender_name)
    Nickel.CreateThread(function()
        Updater.check(true)
    end)
    return true
end