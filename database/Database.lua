local sqlite3 = require("lsqlite3")

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


function DatabaseManager:returnQuery(query)
  local msg = self.db:exec(query)
  print("Changes = ", self.db:changes())
  if self.db:changes() == 0 then
    return "nickel.nochange"
  end
  return msg
end




function DatabaseManager:insertOrUpdateObject(tableName, object, canupdate)

  print("TABLENAME = ", tableName, object)

  local columns = {}
  local values = {}
  local updateColumns = {}
  local columnsOrder = self:getTableColumnsName(tableName)
  local firstColumn
  print("columnsOrder : ", columnsOrder)
  -- Recherchez la première colonne non nulle et non vide
  for _, columnName in ipairs(columnsOrder) do
    if object[columnName] ~= nil and object[columnName] ~= "" then
      firstColumn = columnName
      break
    end
  end
  print("first column is", firstColumn)

  for key, value in pairs(object) do
    table.insert(columns, key)
    if type(value) == "table" then
      -- Convert table to a string representation
      value = utils.table_to_string(value)
    elseif type(value) == "boolean" then
      if value then
        value = 1
      else
        value = 0
      end
    end

    table.insert(values, tostring(value))
    table.insert(updateColumns, string.format("%s = '%s'", key, tostring(value)))
  end

  print("DEBUG IMPORTANT :", firstColumn)


  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s", tableName, firstColumn .. " = '" .. tostring(object[firstColumn]) .. "'") --watch out, problems can happen maybe (black magic)
  print(selectQuery)
  local count = 0
  for row in self.db:nrows(selectQuery) do
    print("ROW IS : ", row)
    count = tonumber(row["COUNT(*)"])
  end

  print(canupdate)
  if count > 0 and canupdate then

      -- Suppose que le nom de la colonne qui identifie de manière unique la ligne est 'beammpid'.
      local updateQuery = string.format("UPDATE %s SET %s WHERE %s = '%s'", tableName, table.concat(updateColumns, ", "), firstColumn, tostring(object[firstColumn]))
      print(updateQuery)
      return self:returnQuery(updateQuery)
  else
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES ('%s')", tableName, table.concat(columns, ", "), table.concat(values, "', '"))
    print(insertQuery)
    return self:returnQuery(insertQuery)
  end
end


function DatabaseManager:getEntry(class, columnName, columnValue)

  print(class,columnName, columnValue)

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
function DatabaseManager:deleteObject(class, conditions)
  local tableName = class.tableName

  if not conditions or #conditions == 0 then
      print("No conditions provided for deletion.")
      return
  end

  local whereClauses = {}
  for i, condition in ipairs(conditions) do
      local columnName, columnValue = condition[1], condition[2]
      local whereClause = string.format("%s = '%s'", columnName, tostring(columnValue))
      table.insert(whereClauses, whereClause)
  end

  local whereClauseString = table.concat(whereClauses, " AND ")
  local deleteQuery = string.format("DELETE FROM %s WHERE %s", tableName, whereClauseString)
  
  return self:returnQuery(deleteQuery)

  -- TODO: Do that for every databases that need to be synced
end


function DatabaseManager:save(class, canupdate)
  if canupdate == nil then
    canupdate = true
  end
  self:openConnection()
  local tableName = class.tableName
  local result = self:insertOrUpdateObject(tableName, class, canupdate)
  self:closeConnection()
  return result
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

function DatabaseManager:getAllEntry(class, conditions)
  local tableName = class.tableName
  local query = "SELECT * FROM " .. tableName

  -- Ajouter des conditions à la requête si elles sont fournies
  if conditions and #conditions > 0 then
    local whereClauses = {}
    for i, condition in ipairs(conditions) do
      local columnName, columnValue = condition[1], condition[2]
      local whereClause = string.format("%s = '%s'", columnName, tostring(columnValue))
      table.insert(whereClauses, whereClause)
    end
    local whereClauseString = table.concat(whereClauses, " AND ")
    query = query .. " WHERE " .. whereClauseString
  end

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

-- Méthode pour obtenir les colonnes existantes de la table
function DatabaseManager:getTableColumnsName(tableName)

  local columns = {}
  for row in self.db:nrows("PRAGMA table_info(" .. tableName .. ")") do
    table.insert(columns, row.name)
  end
  return columns
end


function DatabaseManager:openConnection()
  print("DB OPENED")
  self.db = sqlite3.open(self.dbname)
end

function DatabaseManager:closeConnection()
  if self.db then
    print("DB CLOSED")
    self.db:close()
    self.db = nil
  end
end
return DatabaseManager
