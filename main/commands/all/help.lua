
local utils = require("utils.misc")
local command = {
    type="global",
    args = {
    }
}
--- command
---@param managers managers
function command.init(sender_id, sender_name, managers)
    local permManager = managers.permManager
    local msgManager = managers.msgManager
    local cfgManager = managers.cfgManager
    local dbManager = managers.dbManager
    local commands = managers.commands
    
    local prefix = cfgManager:GetSetting("commands").prefix

    local li = ""
    
    for command in pairs(commands) do
        li = li .. "<li style='color: #A1A1A1; font-weight: bold; font-decoration: underline;'>" .. prefix .. command .. " | <span style='color: #F27D16; font-style: italic;'>" .. commands[command].description .. "</span></li>"
    end

    local html = [[
        <div>
            <h1 style="color: #A1A1A1;">[Nickel] <span style="font-size: 24px; color: #F27D16">Help :</span></h1>
            <ul>
            ]] .. li .. [[
            </ul>
        </div>
    ]]



    msgManager:SendHTMLMessage(sender_id, html)

    return true
end

return command