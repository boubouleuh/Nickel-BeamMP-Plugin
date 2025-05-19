local toml = require("toml")
local new = require("objects.New")
local utils = require("utils.misc")
---@class Settings
local Settings = {}

-- Fonction pour charger la configuration à partir d'un fichier existant
function Settings.loadExistingConfig()
    local existingConfigPath = utils.script_path() .. "NickelConfig/NickelConfig.toml"
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
            if dest[key] == nil then -- Ne remplace que si la clé n'existe pas
                dest[key] = value
            end
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
            autoupdate = true,
            debug = false
        },
        client = {
            interface = false,
            environment = {
                temperature = 20,
                time = {10, 20},
                gravity = -9.81,
                wind = 0,
                meteo = "sunny"
            },
            interfaceValues = {
                showNameplates = true
            }
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
    toml.encodeToFile(self.config, {file = utils.script_path() .. "NickelConfig/NickelConfig.toml", overwrite = true})

    return new._object(Settings, self)
end

-- Fonction pour obtenir une valeur spécifique du fichier de configuration
function Settings:GetSetting(settingKey)
    return self.config[settingKey]
end

local function convertStringsToBooleans(value)
    if type(value) == "string" then
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        end
    elseif type(value) == "table" then
        -- Parcourir la table et convertir récursivement
        for k, v in pairs(value) do
            value[k] = convertStringsToBooleans(v)
        end
    end
    return value
end

function Settings:SetSetting(settingKey, value)
    -- Convertir les chaînes "true"/"false" en booléens, y compris dans les tables
    value = convertStringsToBooleans(value)

    -- Séparer les sous-clés par le séparateur "."
    local keys = {}
    for key in string.gmatch(settingKey, "[^%.]+") do
        table.insert(keys, key)
    end

    -- Parcourir les sous-clés pour atteindre la bonne profondeur
    local current = self.config
    for i = 1, #keys - 1 do
        local key = keys[i]
        if current[key] == nil then
            current[key] = {} -- Créer une table si elle n'existe pas
        end
        current = current[key]
    end

    -- Définir la valeur à la clé finale
    print("Setting " .. keys[#keys] .. " to " .. tostring(value))
    current[keys[#keys]] = value

    -- Réécrire le fichier TOML
    toml.encodeToFile(self.config, {file = utils.script_path() .. "NickelConfig/NickelConfig.toml", overwrite = true})
end

return Settings