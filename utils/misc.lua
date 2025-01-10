

-- Database Management Class
local Misc = {}
---script_path
---@return string --get the script path
function Misc.script_path()
  local separator = package.config:sub(1, 1) -- Obtient le séparateur de chemin d'accès ("/" ou "\")
  local scriptPath = debug.getinfo(1, "S").source:sub(2):gsub("[\\/][^\\/]+$", separator)
  local scriptDir = scriptPath:gsub(separator .. "utils" .. separator .. "$", separator)
  return scriptDir
end

function Misc.capitalize(str)
  return (str:gsub("^%l", string.upper))
end


function Misc.getLinuxVersion()
    local handle = io.popen("lsb_release -ds")
    local result = handle:read("*a")
    handle:close()
    return result
end

function Misc.get_key_for_value( t, value )
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
function Misc.element_exist_in_table(element, list)
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
function Misc.deepCompare(t1, t2)
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= "table" then return t1 == t2 end
  
  for k, v in pairs(t1) do
      if not Misc.deepCompare(v, t2[k]) then return false end
  end
  
  for k, v in pairs(t2) do
      if t1[k] == nil then return false end
  end
  
  return true
end

---mergeTables |
-- merge two tables together
---@param table1 table
---@param table2 table
---@return table
function Misc.mergeTables(table1, table2)
  for i = 1, #table2 do
      table1[#table1 + 1] = table2[i]
  end
  return table1
end


---table_to_string |
-- Invert of string_to_table()
---@param tbl table
---@return string
function Misc.table_to_string( tbl )
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
function Misc.string_to_table(text)
  text = text:gsub("[{}]", "")

  local ipTable = {}
  for ip in text:gmatch("([^,]+)") do
    table.insert(ipTable, ip)
  end

  return ipTable
end

---getPlayerBeamMPID
---@param player_name string
---@return number
function Misc.getPlayerBeamMPID(player_name) --Playername only used when using the web api

  local online = require "main.online"
  local player_id = Misc.GetPlayerId(player_name)
  local identifiers = MP.GetPlayerIdentifiers(player_id)
  if player_id == -1 then
        local playerJson = online.getPlayerJson(player_name)
        local beamid
        if playerJson ~= nil then
            beamid = playerJson.user.id
        end
        return beamid
  end
  local player_beammp_id = identifiers['beammp']
  if player_beammp_id == nil then
      return -1
  end
  return player_beammp_id
end

function Misc.getBeamMPConfig() 
  local toml = require("toml")
  local existingConfigPath = "ServerConfig.toml"
  if FS.Exists(existingConfigPath) then
      return toml.decodeFromFile(existingConfigPath)
  end
end

---GetPlayerId
---@param player_name string
---@return number
function Misc.GetPlayerId(player_name)
  local players = MP.GetPlayers()
  for key, value in pairs(players) do
      if value == player_name then
          return key
      end
  end
  return -1
end


---print_color |
-- Its better to use the nkprint function than this
---@param message string
---@param color string Can be "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white", "gray"
---@return string
function Misc.print_color(message, color)
    -- Les codes de couleur ANSI pour différentes couleurs
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

    -- Vérifie si la couleur spécifiée est valide
    if not colors[color] then
        color = "white"
    end

    -- Affiche le message dans la couleur spécifiée
    return colors[color] .. message .. "\27[0m"
end

---nkprint
---@param message string
---@param type string Can be "warn", "error", "info" or "debug"
---@return nil
function Misc.nkprint(message, type)
  
    if type == "warn" then
        print(Misc.print_color("[NICKEL", "gray") .. Misc.print_color("|WARN] " .. message, "yellow"))
    elseif type == "error" then
        print(Misc.print_color("[NICKEL", "gray") .. Misc.print_color("|ERROR] " .. message, "red"))
    elseif type == "info" then
        print(Misc.print_color("[NICKEL", "gray") .. Misc.print_color("|INFO] " .. message, "blue"))
    elseif type == "debug" then
      -- Miscellanous
      local config = require("main.config.Settings")
      -- Instances
      local cfgManager = config.init()
      if cfgManager:GetSetting("advanced").debug then
        print(Misc.print_color("[NICKEL", "gray") .. Misc.print_color("|DEBUG] " .. message, "cyan"))
      end
    end
end
---timeConverter
---@param time string 1d 1s 1m 1h
---@return nil | number
function Misc.timeConverter(time)
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


return Misc;