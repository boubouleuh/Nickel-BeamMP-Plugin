
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

function MessagesHandler:sendMessage(sender_id, messageKey)

    local color = "^l^7"  -- Couleur
    local style = "^r^o"  -- Style


    local formattedMessage = color .. style .. self:GetMessage(sender_id, messageKey) .. "^r"
    if sender_id == nil then
        return formattedMessage  -- Afficher dans la console
    else
        MP.SendChatMessage(sender_id, formattedMessage)  -- Envoyer au joueur
    end
end

function MessagesHandler:GetMessage(sender_id, key)
    local beamId = utils.getPlayerBeamMPID(sender_id)

    local userLang = self.dbManager:getClassByBeammpId(user, beamId)
    local langCode = self.configManager.config.langs.server_language
    local langForce = self.configManager.config.langs.force_server_language
    if userLang.language ~= nil and langForce == false then
        langCode = userLang.language
    end
    local jsonFile = io.open(utils.script_path() .. "main/lang/all/" .. langCode .. ".json", "r")
    local jsonFileContent = jsonFile:read("a")
    jsonFile:close()
    local json = Util.JsonDecode(jsonFileContent)

    return json[key]

end

return MessagesHandler