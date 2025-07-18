
local utils = require("utils.misc")
local new = require("objects.New")

local user = require("objects.User")

---@class MessagesHandler
MessagesHandler = {}

function MessagesHandler.new(dbManager, configManager)
    local self = {}

    self.dbManager = dbManager
    self.configManager = configManager
    return new._object(MessagesHandler, self)
  end

  function MessagesHandler:SendMessage(sender_id, messageKey, values)
    local chatcolor = "^l^7"
    local chatstyle = "^r^o"

    local consolecolor = "\x1b[1m\x1b[96m[\x1b[90mNickel\x1b[96m]\x1b[49m\x1b[90m : \x1b[21m\x1b[0m\x1b[93m"

    local formattedMessage = chatcolor .. "[Nickel]" .. chatstyle .. self:GetMessage(sender_id, messageKey, values) .. "^r"

    local consoleFormattedMessage = consolecolor .. self:GetMessage(sender_id, messageKey, values) .. "\x1b[39m\x1b[49m\x1b[0m"

    if sender_id == -2 then
        print(consoleFormattedMessage)
    else
        MP.SendChatMessage(sender_id, formattedMessage)
    end
end

function MessagesHandler:SendHTMLMessage(sender_id, html)
    local consolecolor = "\x1b[1m\x1b[96m[\x1b[90mNickel\x1b[96m]\x1b[49m\x1b[90m : \x1b[21m\x1b[0m\x1b[93m"

    local consoleMessage = html
        :gsub("<h%d[^>]*>(.-)</h%d>", "\x1b[1m%1\x1b[22m")
        :gsub("<div[^>]*>%s*(.-)</div>", "%1\n")
        :gsub("<p[^>]*>%s*(.-)</p>", "%1\n") 
        :gsub("<ul[^>]*>%s*", "")
        :gsub("%s*</ul>", "\n")
        :gsub("<li[^>]*>%s*(.-)</li>%s*", "• %1\n")
        :gsub("<span[^>]*>(.-)</span>", "%1")
        :gsub("<br>", "\n")
        :gsub("<br/>", "\n")
        :gsub("<b>(.-)</b>", "\x1b[1m%1\x1b[22m")
        :gsub("<i>(.-)</i>", "\x1b[3m%1\x1b[23m")
        :gsub("<u>(.-)</u>", "\x1b[4m%1\x1b[24m")
        :gsub("<strong>(.-)</strong>", "\x1b[1m%1\x1b[22m")
        :gsub("<em>(.-)</em>", "\x1b[3m%1\x1b[23m")
        :gsub("<[^>]+>", "")
        :gsub("\n\n+", "\n")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
        :gsub("\n%s+", "\n")

    local consoleFormattedMessage = consolecolor .. consoleMessage .. "\x1b[39m\x1b[49m\x1b[0m"

    if sender_id == -2 then
        print(consoleFormattedMessage)
    else
        html = html:gsub("\n", "")
        MP.SendChatMessage(sender_id, html)
    end
end

function MessagesHandler:GetMessage(sender_id, key, values)
    local beamId
    if sender_id ~= -2 and sender_id ~= -1 then
        beamId = utils.getPlayerBeamMPID(MP.GetPlayerName(sender_id))
    end
    local userLang = self.dbManager:withConnection(function()
        local userLang
        if beamId ~= nil then
            userLang = self.dbManager:getClassByBeammpId(user, beamId)
        end
        return userLang
    end)
    local langCode = self.configManager:GetSetting("langs").server_language
    local langForce = self.configManager:GetSetting("langs").force_server_language

    if userLang ~= nil and userLang.language ~= nil and not langForce then
        langCode = userLang.language
    end

    local jsonFile = io.open(utils.script_path() .. "main/lang/all/" .. langCode .. ".json", "r")
    local jsonFileContent = jsonFile:read("a")
    jsonFile:close()

    local json = Util.JsonDecode(jsonFileContent)
    
    local message = json[key]
    if message == nil then
        message = key
        if values then
            for placeholder, value in pairs(values) do
                message = message:gsub("{" .. placeholder .. "}", value)
            end
        end
    else
        if values then
            for placeholder, value in pairs(values) do
                message = message:gsub("{" .. placeholder .. "}", value)
            end
        end
    end

    return message
end


return MessagesHandler