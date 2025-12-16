
ConfigManager = {}
function ConfigManager.loadExistingConfig()
    local existingConfigPath = Utils.script_path() .. "NickelConfig.toml"
    if FS.Exists(existingConfigPath) then
        return TOML.decodeFromFile(existingConfigPath)
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

function ConfigManager.init()
    ConfigManager.config = ConfigManager.loadExistingConfig()
    local configChanged = false
    
   local defaultConfig = {
        discord = {
            chat_webhook = "",
            vehicle_webhook = "",
            player_webhook = "",
        },
        misc = {
            join_message = "[{Role}] {Player} joined the server",
            chat_log = true,
        },
        langs = {
            server_language = "en_us",
            force_server_language = false
        },
        commands = {
            prefix = "/"
        },
        database = {
            type = "sqlite",
            file = "database/nickel.sqlite",
            host = "localhost",
            port = 3306,
            name = "nickel",
            username = "",
            password = "",
            ssl = false
        },
        conditions = {
            whitelist = false,
            guest = false
        },
        advanced = {
            autoupdate = true,
            update_type = "tags", -- "tags" or "commit"
            target = "main",
            debug = false
        },
        client = {
            b64avatar = true,
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

    if needsMerge(ConfigManager.config, defaultConfig) then
        mergeTables(ConfigManager.config, defaultConfig)
        configChanged = true
    end

    local function recursiveCleanup(existing, default)
        local changed = false
        for key, value in pairs(existing) do
            if default[key] == nil then
                existing[key] = nil
                changed = true
            elseif type(value) == "table" and type(default[key]) == "table" then
                if recursiveCleanup(value, default[key]) then
                    changed = true
                end
            end
        end
        return changed
    end

    if recursiveCleanup(ConfigManager.config, defaultConfig) then
        configChanged = true
    end

    if configChanged then
        TOML.encodeToFile(ConfigManager.config, {
            file = Utils.script_path() .. "NickelConfig.toml",
            overwrite = true
        })
    end

    return ConfigManager
end

function ConfigManager.GetSetting(settingKey)
    return ConfigManager.config[settingKey]
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

function ConfigManager.SetSetting(settingKey, value)
    value = convertStringsToBooleans(value)

    local keys = {}
    for key in string.gmatch(settingKey, "[^%.]+") do
        table.insert(keys, key)
    end

    local current = ConfigManager.config
    for i = 1, #keys - 1 do
        local key = keys[i]
        if current[key] == nil then
            current[key] = {} 
        end
        current = current[key]
    end

    print("Setting " .. keys[#keys] .. " to " .. tostring(value))
    current[keys[#keys]] = value

    TOML.encodeToFile(ConfigManager.config, {file = Utils.script_path() .. "NickelConfig.toml", overwrite = true})
end
ConfigManager.init()