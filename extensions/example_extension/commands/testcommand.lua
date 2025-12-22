
local command = RegisterCommand("testcommand", {
    type = "global",
    args = {
        {name = "message", type = "string"} --this is for showing it in the interface
    }
})

function command.init(sender_id, sender_name) --add parameters here

    MessagesManager:SendMessage(sender_id, "the test is successfull")

    return true --if the command is successfull otherwise you will need to return false !
end