
local command = RegisterCommand("help", {
    type="global",
    args = {
    }
})

--- command
function command.init(sender_id, sender_name)
    local prefix = ConfigManager.GetSetting("commands").prefix

    local li = ""
    
    for commandName in pairs(NickelCommands or {}) do
        local description = NickelCommands[commandName].description or "No description"
        li = li .. "<li style='color: #A1A1A1; font-weight: bold; font-decoration: underline;'>" .. prefix .. commandName .. " | <span style='color: #F27D16; font-style: italic;'>" .. description .. "</span></li>"
    end

    local html = [[
        <div>
            <h1 style="color: #A1A1A1;">[Nickel] <span style="font-size: 24px; color: #F27D16">Help :</span></h1>
            <ul>
            ]] .. li .. [[
            </ul>
        </div>
    ]]

    MessagesManager:SendHTMLMessage(sender_id, html)

    return true
end