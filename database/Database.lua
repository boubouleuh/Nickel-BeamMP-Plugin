local sqlite3 = require("lsqlite3complete")

local new = require("objects.New")

local utils = require("utils.misc")

-- Database Management Class
local DatabaseManager = {}

function DatabaseManager.new(databaseName)
  local self = {}
  -- self.db = sqlite3.open(databaseName)
  self.dbname = databaseName
  return new._object(DatabaseManager, self)
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columns, ", "))
  self.db:exec(query)
end


function DatabaseManager:insertOrUpdateObject(tableName, object)


  local columns = {}
  local values = {}
  local updateColumns = {}


  for key, value in pairs(object) do
    table.insert(columns, key)

    if type(value) == "table" then
      -- Convert table to a string representation
      value = utils.table_to_string(value)
      print(value)
    end

    table.insert(values, tostring(value))
    table.insert(updateColumns, string.format("%s = '%s'", key, tostring(value)))
  end

  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s", tableName, columns[1] .. " = '" .. tostring(object[columns[1]]) .. "'")
  print(selectQuery)
  local count = 0
  for row in self.db:nrows(selectQuery) do
    count = tonumber(row["COUNT(*)"])
  end

  if count > 0 then
    local updateQuery = string.format("UPDATE %s SET %s WHERE %s", tableName, table.concat(updateColumns, ", "), columns[1] .. " = '" .. tostring(object[columns[1]]) .. "'")
    print(updateQuery)
    self.db:exec(updateQuery)
  else
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES ('%s')", tableName, table.concat(columns, ", "), table.concat(values, "', '"))
    print(insertQuery)
    self.db:exec(insertQuery)
  end

  -- TODO Do that for every databases that need to be synced

end

function DatabaseManager:getEntry(class, columnName, columnValue)

  local tableName = class.tableName
  local query = string.format("SELECT * FROM %s WHERE %s = '%s'", tableName, columnName, tostring(columnValue))
  local results = {}

  for row in self.db:nrows(query) do
    table.insert(results, row)    
    break
  end

  return results[1]
end

-- TODO IMPORTANT ! WHEN TRYING TO SYNC WE NEED TO MAKE SURE THE VERSION OF EVERY NICKEL IS THE SAME ! IF ITS NOT THE SAME AN ERROR OCCURS AND ASK TO UPDATE EVERY NICKEL AND THEN RESTART ! (AT THE RESTART IT WILL COMPARE EVERY DATABASE TO SYNC IF THERE IS PROBLEM)
-- TODO THE FUTUR AUTO UPDATE VAR IN THE CONFIG NEED TO BE THE SAME TO ACTIVATE THE SYNC
function DatabaseManager:deleteObject(class, columnName, columnValue)

  local tableName = class.tableName
  local deleteQuery = string.format("DELETE FROM %s WHERE %s = '%s'", tableName, columnName, tostring(columnValue))
  self.db:exec(deleteQuery)

  -- TODO Do that for every databases that need to be synced
end

function DatabaseManager:save(class)
  self:openConnection()
  local tableName = class.tableName
  self:insertOrUpdateObject(tableName, class)
  self:closeConnection()
end

-- Dans la classe DatabaseManager
function DatabaseManager:createTableForClass(class)

  local tableName = class.tableName
  local columns = class:getColumns()
  local existingColumns = self:getTableColumns(tableName)

  -- Si la table n'existe pas, créez-la
  if not next(existingColumns) then
    self:createTableIfNotExists(tableName, columns)
  else
      local existingColumnsFinal = {}
      local columnsFinal = {}

      for key2, _ in pairs(existingColumns) do
          table.insert(existingColumnsFinal, key2)
      end

      for key, column in ipairs(columns) do
        local colName = column:match("^(%S+)")
        local finalKey = utils.get_key_for_value(existingColumnsFinal, colName)
        if finalKey ~= nil then
          columnsFinal[finalKey] = colName
        end
      end

      -- Si la colonne de la table ne correspond à aucune colonne de la classe, supprimez-la
      for key, column in ipairs(existingColumnsFinal) do

        if columnsFinal[key] == nil then
          local alterQuery = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, column)
          self.db:exec(alterQuery)
        end
      end

    -- Ajoutez les colonnes manquantes
    for _, column in ipairs(columns) do
      local colName = column:match("^(%S+)")
      if not existingColumns[colName] then
        local alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s", tableName, column)
        print(alterQuery)
        self.db:exec(alterQuery)
      end
    end
  end

end

function DatabaseManager:getAllEntry(class)

  local tableName = class.tableName
  local query = string.format("SELECT * FROM %s", tableName)
  local results = {}

  for row in self.db:nrows(query) do
    local result = class.new()

    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = utils.string_to_table(value)
        result:setKey(key, parsedList)
      else
        result:setKey(key, value)
      end
    end

    table.insert(results, result)
  end
  return results
end

function DatabaseManager:getClassByBeammpId(class, beammpid)
  local tableName = class.tableName
  local query = string.format("SELECT * FROM %s WHERE beammpid = %s LIMIT 1", tableName, tostring(beammpid))
  local result = nil

  for row in self.db:nrows(query) do
    result = class.new()

    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = utils.string_to_table(value)
        result:setKey(key, parsedList)
      else
        -- Utilisez une méthode set ou affectez directement les valeurs aux propriétés de la classe
        result:setKey(key, value)  -- Assurez-vous que votre classe a une méthode set appropriée
      end
    end

    break -- Assuming beammpid is unique, so we break after finding the first match
  end


  return result
end





-- Méthode pour obtenir les colonnes existantes de la table
function DatabaseManager:getTableColumns(tableName)


  local existingColumns = {}
  local query = string.format("PRAGMA table_info(%s)", tableName)

  for row in self.db:nrows(query) do
    existingColumns[row.name] = true
  end

  return existingColumns
end





function DatabaseManager:openConnection()
  self.db = sqlite3.open(self.dbname)
end

function DatabaseManager:closeConnection()
  if self.db then
    self.db:close()
    self.db = nil
  end
end
return DatabaseManager
