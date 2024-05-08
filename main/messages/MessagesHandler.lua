
local utils = require("utils.misc")
local new = require("objects.New")

local user = require("objects.User")

MessagesHandler = {}

function MessagesHandler.new(dbManager, configManager)
    local self = {}

    self.dbManager = dbManager
    self.configManager = configManager
    return new._object(MessagesHandler, self)
  end

function MessagesHandler:SendMessage(sender_id, messageKey, ...)
    local chatcolor = "^l^7"  -- Couleur
    local chatstyle = "^r^o"  -- Style

    local consolecolor = "\x1b[1m\x1b[96m[\x1b[90mNickel\x1b[96m]\x1b[49m\x1b[90m : \x1b[21m\x1b[0m\x1b[93m"

    local formattedMessage = chatcolor .. chatstyle .. self:GetMessage(sender_id, messageKey, ...) .. "^r"

    local consoleFormattedMessage = consolecolor .. self:GetMessage(sender_id, messageKey, ...) .. "\x1b[39m\x1b[49m\x1b[0m"

    if sender_id == -2 then
        print(consoleFormattedMessage)  -- Afficher dans la console
    else
        MP.SendChatMessage(sender_id, formattedMessage)  -- Envoyer au joueur
    end
end

function MessagesHandler:GetMessage(sender_id, key, ...)


    local beamId
    if sender_id ~= -2 then
        beamId = utils.getPlayerBeamMPID(MP.GetPlayerName(sender_id))
    end
    self.dbManager:openConnection()
    local userLang
    if beamId ~= nil then
        userLang = self.dbManager:getClassByBeammpId(user, beamId)
    end
    self.dbManager:closeConnection()
    local langCode = self.configManager:GetSetting("langs").server_language
    local langForce = self.configManager:GetSetting("langs").force_server_language

    if userLang ~= nil and userLang.language ~= nil and not langForce then
        langCode = userLang.language
    end

    local jsonFile = io.open(utils.script_path() .. "main/lang/all/" .. langCode .. ".json", "r")
    local jsonFileContent = jsonFile:read("a")
    jsonFile:close()

    local json = Util.JsonDecode(jsonFileContent)
    
    if json[key] ~= nil then
        local message = json[key]

        local args = {...}

        for i, var in ipairs(args) do
            local placeholder = "{(.-)}"
            message = message:gsub(placeholder, var, 1)
        end

        return message
    else
        return key
    end
end



return MessagesHandler