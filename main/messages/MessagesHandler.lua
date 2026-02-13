MessagesManager = {}

local langCache = {}

function MessagesManager:SendMessage(sender_id, messageKey, values)
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

function MessagesManager:SendHTMLMessage(sender_id, html)
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

function MessagesManager:GetMessage(sender_id, key, values)
    local beamId
    if sender_id ~= -2 and sender_id ~= -1 then
        beamId = Utils.getPlayerBeamMPID(MP.GetPlayerName(sender_id))
    end
    local userLang = DatabaseManager:withConnection(function()
        local userLang
        if beamId ~= nil then
            userLang = DatabaseManager:getClassByBeammpId(User, beamId)
        end
        return userLang
    end)
    local langCode = ConfigManager.GetSetting("langs").server_language
    local langForce = ConfigManager.GetSetting("langs").force_server_language

    if userLang ~= nil and userLang ~= false and userLang.language ~= nil and not langForce then
        langCode = userLang.language
    end

    -- Use cached parsed JSON; only read file on first access per language
    if not langCache[langCode] then
        local jsonFile = io.open(Utils.script_path() .. "main/lang/all/" .. langCode .. ".json", "r")
        if jsonFile then
            local jsonFileContent = jsonFile:read("a")
            jsonFile:close()
            langCache[langCode] = Util.JsonDecode(jsonFileContent)
        else
            langCache[langCode] = {}
        end
    end
    local json = langCache[langCode]
    
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