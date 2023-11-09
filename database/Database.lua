local sqlite3 = require("lsqlite3complete")


local new = require("objects.New")

local utils = require("utils.misc")

-- Database Management Class
local DatabaseManager = {}

function DatabaseManager.new(databaseName)
  local self = {}
  self.db = sqlite3.open(databaseName)
  return new._object(DatabaseManager, self)
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columns, ", "))
  self.db:exec(query)
end

function DatabaseManager:insertOrUpdateObject(tableName, object)
  local columns = {}
  local values = {}
  local modifications = {}

  for key, value in pairs(object) do
    table.insert(columns, key)
    table.insert(values, tostring(value))
    table.insert(modifications, string.format("%s = '%s'", key, tostring(value))
    )
  end

  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s", tableName, table.concat(modifications, " AND "))

  local count = 0
  for row in self.db:nrows(selectQuery) do
    count = tonumber(row["COUNT(*)"])
  end

  if count > 0 then
    local updateQuery = string.format("UPDATE %s SET %s WHERE %s", tableName, table.concat(modifications, ", "), table.concat(modifications, " AND "))
    self.db:exec(updateQuery)
  else
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES ('%s')", tableName, table.concat(columns, ", "), table.concat(values, "', '"))
    self.db:exec(insertQuery)
  end
end

function DatabaseManager:save(class)
  local tableName = class.tableName
  self:insertOrUpdateObject(tableName, class)
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
          print(alterQuery)
          self.db:exec(alterQuery)
        end
      end

    -- Ajoutez les colonnes manquantes
    for _, column in ipairs(columns) do
      local colName = column:match("^(%S+)")
      if not existingColumns[colName] then
        local alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s", tableName, column)
        self.db:exec(alterQuery)
      end
    end
  end
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






function DatabaseManager:closeConnection()
  self.db:close()
end

return DatabaseManager
