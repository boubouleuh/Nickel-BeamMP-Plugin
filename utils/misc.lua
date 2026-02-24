

Utils = {}
---script_path
---@return string --get the script path
function Utils.script_path()
  local str = debug.getinfo(1, "S").source
  if str:sub(1, 1) == "@" then
    str = str:sub(2)
  end
  str = str:gsub("\\", "/")
  str = str:match("(.*/)")
  str = str:gsub("utils/$", "")
    if package.config:sub(1, 1) == "\\" then
    str = str:gsub("/", "\\")
  end
  return str
end

function Utils.extension_path()
  local str = debug.getinfo(2, "S").source
  if str:sub(1, 1) == "@" then
    str = str:sub(2)
  end
  str = str:gsub("\\", "/")
  
  local extensionName = str:match("extensions/([^/]+)/")
  
  if not extensionName then
      error("Utils.extension_path() called from outside an extension: " .. str)
  end
  local root = str:match("(.*/extensions/[^/]+/)")
  if package.config:sub(1, 1) == "\\" then
    root = root:gsub("/", "\\")
  end
  return root
end

function Utils.capitalize(str)
  return (str:gsub("^%l", string.upper))
end

function Utils.get_key_for_value( t, value )
    for k,v in pairs(t) do
      if v==value then return k end
    end
    return nil
end

---table_to_string |
-- if the element exist in the table
---@param element string
---@param list table
---@return boolean
function Utils.element_exist_in_table(element, list)
  -- Check if the element exists in the list
  if type(list) == "table" then
    for key, value in next, list do
      if value == element then
        return true  -- Element already exists
      end
    end
  end
  return false  -- Element does not exist or invalid input
end

--- deepCompare |
-- Compare two tables
---@param t1 table
---@param t2 table
---@return boolean
function Utils.deepCompare(t1, t2, visited)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end

    if getmetatable(t1) ~= getmetatable(t2) then return false end

    visited = visited or {}
    if visited[t1] and visited[t1] == t2 then return true end
    visited[t1] = t2

    local function tableLength(t)
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end

    if tableLength(t1) ~= tableLength(t2) then return false end

    for k, v in pairs(t1) do
        if not Utils.deepCompare(v, t2[k], visited) then return false end
    end

    for k, v in pairs(t2) do
        if t1[k] == nil then return false end
    end

    return true
end

--- shallowcopy |
-- Clone a table
---@param orig table
---@return table
function Utils.shallowCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in pairs(orig) do
          copy[orig_key] = orig_value
      end
  else -- number, string, boolean, etc
      copy = orig
  end
  return copy
end

---mergeTables |
-- merge two tables together
---@param table1 table
---@param table2 table
---@return table
function Utils.mergeTables(table1, table2)
  for i = 1, #table2 do
      table1[#table1 + 1] = table2[i]
  end
  return table1
end


---table_to_string |
-- Invert of string_to_table()
---@param tbl table
---@return string
function Utils.table_to_string( tbl )
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, v )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        k .. "=" .. v )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end


---string_to_table |
-- Convert string like "{a,a,a}" to a table
---@param text string
---@return table
function Utils.string_to_table(text)
  text = text:gsub("[{}]", "")

  local ipTable = {}
  for ip in text:gmatch("([^,]+)") do
    table.insert(ipTable, ip)
  end

  return ipTable
end

function Utils.split(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

---getPlayerBeamMPID
---@param player_nameORid string|number
---@return number
function Utils.getPlayerBeamMPID(player_nameORid)
    local player_id
    local player_name
    if type(player_nameORid) == "string" then
        player_id = Utils.GetPlayerId(player_nameORid)
        player_name = player_nameORid
    else
        player_id = player_nameORid
    end
    if player_id ~= -1 then
        local identifiers = MP.GetPlayerIdentifiers(player_id)
        local beammp_id = identifiers['beammp']
        if beammp_id then
            return beammp_id
        end
    end

    local user = User.findByName(player_name)
    if user then
        return user.beammpid
    end

    local playerJson = Online.getPlayerJson(player_name)
    if playerJson ~= nil then
        return playerJson.user.id
    end


    return -1
end

function Utils.getBeamMPConfig() 
  local config = { General = {} } -- Default structure to avoid nil indexing
  local existingConfigPath = "ServerConfig.toml"
  if FS.Exists(existingConfigPath) then
      local loaded_config = TOML.decodeFromFile(existingConfigPath)
      if loaded_config then
          config = loaded_config
      end
  end

  -- Ensure General table exists
  if not config.General then config.General = {} end

  -- Helper function to apply env vars
  local function applyEnv(field, key, type)
      local val = os.getenv(key)
      if val then
          if type == "boolean" then
              config.General[field] = (val == "true" or val == "1")
          elseif type == "number" then
              config.General[field] = tonumber(val)
          else
              config.General[field] = val
          end
      end
  end

  -- Apply environment variables overrides
  applyEnv("Debug", "BEAMMP_DEBUG", "boolean")
  applyEnv("Private", "BEAMMP_PRIVATE", "boolean")
  applyEnv("Port", "BEAMMP_PORT", "number")
  applyEnv("MaxCars", "BEAMMP_MAX_CARS", "number")
  applyEnv("MaxPlayers", "BEAMMP_MAX_PLAYERS", "number")
  applyEnv("Map", "BEAMMP_MAP", "string")
  applyEnv("Name", "BEAMMP_NAME", "string")
  applyEnv("Description", "BEAMMP_DESCRIPTION", "string")
  applyEnv("Tags", "BEAMMP_TAGS", "string")
  applyEnv("ResourceFolder", "BEAMMP_RESOURCE_FOLDER", "string")
  applyEnv("AuthKey", "BEAMMP_AUTH_KEY", "string")
  applyEnv("LogChat", "BEAMMP_LOG_CHAT", "boolean")

  return config
end

function Utils.getMapName()
    local map = Utils.getBeamMPConfig().General.Map -- /levels/west_coast_usa/info.json example
    if map then
        local mapName = map:match("levels/(.+)/info.json")
        if mapName then
            return mapName:gsub("_", " "):gsub("^%l", string.upper) -- Capitalize the first letter
        end
    end
end

---GetPlayerId
---@param player_name string
---@return number
function Utils.GetPlayerId(player_name)
    return MP.GetPlayerIDByName(player_name)
end


---print_color |
-- Its better to use the nkprint function than this
---@param message string
---@param color string Can be "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "gray"
---@return string
function Utils.print_color(message, color)
    local colors = {
        black = "\27[30m",
        red = "\27[31m",
        green = "\27[32m",
        yellow = "\27[33m",
        blue = "\27[34m",
        magenta = "\27[35m",
        cyan = "\27[36m",
        white = "\27[37m",
        gray = "\27[90m",
    }

    if not colors[color] then
        color = "white"
    end

    return colors[color] .. message .. "\27[0m"
end

---nkprint
---@param message string
---@param type string Can be "warn", "error", "info", "important" or "debug"
---@return nil
function Utils.nkprint(message, type)
  
    if type == "warn" then
        print(Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|WARN] " .. message, "yellow"))
    elseif type == "error" then
        print(Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|ERROR] " .. message, "red"))
    elseif type == "info" then
        print(Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|INFO] " .. message, "blue"))
    elseif type == "important" then
        print(Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|IMPORTANT] " .. message, "magenta"))
    elseif type == "debug" then
      -- Miscellanous
      if ConfigManager and ConfigManager.GetSetting and ConfigManager.GetSetting("advanced") and ConfigManager.GetSetting("advanced").debug then
        print(Utils.print_color("[NICKEL", "gray") .. Utils.print_color("|DEBUG] " .. message, "cyan"))
      end
    end
end
---timeConverter
---@param time string 1d 1s 1m 1h
---@return nil | number
function Utils.timeConverter(time)
    local oldtime = time

    local time = time:lower()
    local time = time:gsub(" ", "")
    local time = time:gsub("s", "")
    local time = time:gsub("m", "")
    local time = time:gsub("h", "")
    local time = time:gsub("d", "")
    local time = tonumber(time)
    if time == nil then
        return nil
    end
    if oldtime:lower():find("s") then
        return time
    elseif oldtime:lower():find("m") then
        return time * 60
    elseif oldtime:lower():find("h") then
        return time * 60 * 60
    elseif oldtime:lower():find("d") then
        return time * 60 * 60 * 24
    else
        return nil
    end
end

local asyncId = 0
local asyncTasks = {}

function Utils.RunAsync(func, delay, ...)
    asyncId = asyncId + 1
    local id = "__async_event_" .. asyncId
    local handlerName = "__async_handler_" .. asyncId
    local args = {...}

    _G[handlerName] = function()
        func(table.unpack(args))
        MP.CancelEventTimer(id)
        _G[handlerName] = nil
        asyncTasks[id] = nil
    end

    asyncTasks[id] = _G[handlerName]

    MP.RegisterEvent(id, handlerName)
    MP.CreateEventTimer(id, delay)
end

function Utils.hotreload()
    Utils.nkprint("Manually hot-reloading Nickel BeamMP Plugin...", "info")
    local path = Utils.script_path() .. "reloader.lua"
    local file = io.open(path, "w")
    if file then
        file:write("return " .. tostring(math.random(1, 1000000)))
        file:close()
    end
end

---tableLength |
-- Get the number of elements in a table (works with string keys)
---@param t table
---@return number
function Utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---isTruthy |
-- Check if a value should be considered as boolean true
-- Recognizes: true, "true", 1, "1" as true
---@param value any
---@return boolean
function Utils.isTruthy(value)
    if value == true or value == 1 then
        return true
    end
    if type(value) == "string" then
        local lower = string.lower(value)
        return lower == "true" or lower == "1"
    end
    return false
end


function Utils.parseBeamData(data)
    local jsonPart = data:match("({.*})")
    return Util.JsonDecode(jsonPart)
end
