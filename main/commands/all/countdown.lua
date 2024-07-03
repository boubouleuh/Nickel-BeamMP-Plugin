
local utils = require("utils.misc")


local command = {}

function command.init(sender_id, sender_name, managers)

    local cfgManager = managers.cfgManager
    local msgManager = managers.msgManager


    local i = 5
    function countdownWork()
        if i == 5 then

            msgManager:SendMessage(-1, "Countdown started")
        end
        if i >= 1 then
            msgManager:SendMessage(-1, i)
        else
            msgManager:SendMessage(-1, "GOOO !")
            MP.CancelEventTimer("countdown")
        end
        i = i - 1
    end
    MP.RegisterEvent("countdown", "countdownWork")
    MP.CreateEventTimer("countdown", 1000)

    return true

end

return command