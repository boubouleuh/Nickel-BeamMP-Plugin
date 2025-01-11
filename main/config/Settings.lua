local toml = require("toml")
local new = require("objects.New")

---@class Settings
local Settings = {}

-- Fonction pour charger la configuration à partir d'un fichier existant
function Settings.loadExistingConfig()
    local existingConfigPath = "NickelConfig.toml"
    if FS.Exists(existingConfigPath) then
        return toml.decodeFromFile(existingConfigPath)
    end
    return {}
end

-- Fonction pour fusionner deux tables de manière récursive
local function mergeTables(dest, src)
    for key, value in pairs(src) do
        if type(value) == "table" then
            dest[key] = dest[key] or {}
            mergeTables(dest[key], value)
        else
            dest[key] = dest[key] or value
        end
    end
end

-- Fonction pour initialiser la configuration
function Settings.init()
    local self = {}
    self.config = Settings.loadExistingConfig()
    local defaultConfig = {
        misc = {
            join_message = "[{Role}] {Player} joined the server",
        },
        langs = {
            server_language = "en_us",
            force_server_language = false
        },
        commands = {
            prefix = "/"
        },
        sync = {
           database_file = ""
        },
        conditions = {
            whitelist = false,
            guest = false
        },
        advanced = {
            debug = false
        },
        client = {
            temperature = 0,
            time = {0, 0},
            gravity = 0,
            wind = 0,
            meteo = "sunny"
        }
    }

    --TODO IN THE DEFAULT CONFIG THINK ABOUT THE OTHER SERVERS VAR WHO WILL CONTAINS EVERY SERVERS DIRECTORY

    -- Fusionne les configurations existantes avec les valeurs par défaut
    mergeTables(self.config, defaultConfig)

    -- Supprime les clés qui n'existent plus dans la configuration par défaut
    for key, _ in pairs(self.config) do
        if defaultConfig[key] == nil then
            self.config[key] = nil
        end
    end

    -- Réécrit le fichier avec les données fusionnées
    toml.encodeToFile(self.config, {file = "NickelConfig.toml", overwrite = true})

    return new._object(Settings, self)
end

-- Fonction pour obtenir une valeur spécifique du fichier de configuration
function Settings:GetSetting(settingKey)
    return self.config[settingKey]
end

function Settings:SetSetting(settingKey, value)
    self.config[settingKey] = value
    toml.encodeToFile(self.config, {file = "NickelConfig.toml", overwrite = true})
end

return Settings