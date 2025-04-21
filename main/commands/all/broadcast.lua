
local utils = require("utils.misc")


local command = {
    type="global",
    args = {
        {name = "message", type = "string"}
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers, message)
    local msgManager = managers.msgManager
    if message == nil then
        msgManager:SendMessage(sender_id, "commands.broadcast.missing_args", {Prefix = managers.cfgManager.config.commands.prefix})
        return false
    end

    msgManager:SendMessage(-1, message)
  
    return true

end

return command