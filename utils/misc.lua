local online = require "main.online"



-- Database Management Class
local Misc = {}

function Misc.script_path()
  local separator = package.config:sub(1, 1) -- Obtient le séparateur de chemin d'accès ("/" ou "\")
  local scriptPath = debug.getinfo(1, "S").source:sub(2):gsub("[\\/][^\\/]+$", separator)
  local scriptDir = scriptPath:gsub(separator .. "utils" .. separator .. "$", separator)
  return scriptDir
end


function Misc.get_key_for_value( t, value )
    for k,v in pairs(t) do
      if v==value then return k end
    end
    return nil
end
  

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

-- Fonction pour convertir la chaîne en une table Lua
function Misc.string_to_table(text)
  text = text:gsub("[{}]", "")

  local ipTable = {}
  for ip in text:gmatch("([^,]+)") do
    table.insert(ipTable, ip)
  end

  return ipTable
end


function Misc.getPlayerBeamMPID(player_id, player_name) --Playername only used when using the web api
  local identifiers = MP.GetPlayerIdentifiers(player_id)
  if identifiers == nil then
      if player_name ~= nil then
        local beamid = online.getPlayerJson(player_name).user.id
        return beamid
      end
      return -1
  end
  local player_beammp_id = identifiers['beammp']
  if player_beammp_id == nil then
      return -1
  end
  return player_beammp_id
end

function Misc.GetPlayerId(player_name)
  local players = MP.GetPlayers()
  for key, value in pairs(players) do
      if value == player_name then
          return key
      end
  end
  return -1
end

return Misc;