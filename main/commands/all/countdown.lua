
local command = RegisterCommand("countdown", {
    type = "global",
    args = {}
})

--- command
function command.init(sender_id, sender_name)
    local i = 5
    
    Nickel.SetInterval(1000, function(timerId)
        if i == 5 then
            MessagesManager:SendMessage(-1, "Countdown started")
        end
        
        if i >= 1 then
            MessagesManager:SendMessage(-1, tostring(i))
        else
            MessagesManager:SendMessage(-1, "GOOO !")
            Nickel.StopThread(timerId)
        end
        i = i - 1
    end)

    return true
end