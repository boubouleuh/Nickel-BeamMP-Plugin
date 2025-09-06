

local command = {
    type = "global",
    args = {}
}

--- command
function command.init(sender_id, sender_name)
    local i = 5
    function _countdownWork()
        if i == 5 then
            MessagesManager:SendMessage(-1, "Countdown started")
        end
        if i >= 1 then
            MessagesManager:SendMessage(-1, tostring(i))
        else
            MessagesManager:SendMessage(-1, "GOOO !")
            MP.CancelEventTimer("countdown")
        end
        i = i - 1
    end
    MP.RegisterEvent("countdown", "_countdownWork")
    MP.CreateEventTimer("countdown", 1000)

    return true
end

RegisterNickelCommand("countdown", command)