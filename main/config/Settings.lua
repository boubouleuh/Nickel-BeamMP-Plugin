local toml = require("toml")
local new = require("objects.New")
local utils = require("utils.misc")
---@class Settings
local Settings = {}

-- Fonction pour charger la configuration à partir d'un fichier existant
function Settings.loadExistingConfig()
    local existingConfigPath = utils.script_path() .. "NickelConfig.toml"
    if FS.Exists(existingConfigPath) then
        return toml.decodeFromFile(existingConfigPath)
    end
    return {}
end

local function mergeTables(dest, src)
    for key, value in pairs(src) do
        if type(value) == "table" then
            dest[key] = dest[key] or {}
            mergeTables(dest[key], value)
        else
            if dest[key] == nil then 
                dest[key] = value
            end
        end
    end
end

function Settings.init()
    local self = {}
    self.config = Settings.loadExistingConfig()
    local configChanged = false
    
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
                weather = "sunny"
            },
            interfaceValues = {
                showNameplates = true
            }
        }
    }

    local function needsMerge(existing, default)
        if type(existing) ~= "table" or type(default) ~= "table" then
            return true
        end
        for k, v in pairs(default) do
            if existing[k] == nil then
                return true
            elseif type(v) == "table" then
                if needsMerge(existing[k], v) then
                    return true
                end
            end
        end
        return false
    end

    if needsMerge(self.config, defaultConfig) then
        mergeTables(self.config, defaultConfig)
        configChanged = true
    end

    for key, _ in pairs(self.config) do
        if defaultConfig[key] == nil then
            self.config[key] = nil
            configChanged = true
        end
    end

if configChanged then
    toml.encodeToFile(self.config, {
        file = utils.script_path() .. "NickelConfig.toml",
        overwrite = true
    })
end

    return new._object(Settings, self)
end

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

        for k, v in pairs(value) do
            value[k] = convertStringsToBooleans(v)
        end
    end
    return value
end

function Settings:SetSetting(settingKey, value)
    value = convertStringsToBooleans(value)

    local keys = {}
    for key in string.gmatch(settingKey, "[^%.]+") do
        table.insert(keys, key)
    end

    local current = self.config
    for i = 1, #keys - 1 do
        local key = keys[i]
        if current[key] == nil then
            current[key] = {} 
        end
        current = current[key]
    end

    print("Setting " .. keys[#keys] .. " to " .. tostring(value))
    current[keys[#keys]] = value

    toml.encodeToFile(self.config, {file = utils.script_path() .. "NickelConfig.toml", overwrite = true})
end

return Settings