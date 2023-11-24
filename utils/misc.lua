


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
  for _, value in ipairs(list) do
    if value == element then
      return true  -- Element already exists
    end
  end
  return false  -- Element does not exist
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


function Misc.getPlayerBeamMPID(player_id)
  local identifiers = MP.GetPlayerIdentifiers(player_id)
  if identifiers == nil then
      return -1
  end
  local player_beammp_id = identifiers['beammp']
  if player_beammp_id == nil then
      return -1
  end
  return player_beammp_id
end

return Misc;