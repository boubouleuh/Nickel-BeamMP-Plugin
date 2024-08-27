local sqlite3 = require("lsqlite3")

local new = require("objects.New")

local utils = require("utils.misc")

local online = require("main.online")

-- Database Management Class
---@class DatabaseManager
local DatabaseManager = {}

function DatabaseManager.new(databaseName)
  local self = {}
  -- self.db = sqlite3.open(databaseName)
  self.dbname = databaseName
  return new._object(DatabaseManager, self)
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columns, ", "))

  print(query)
  self.db:exec(query)
end


function DatabaseManager:returnQuery(query)
  local msg = self.db:exec(query)
  utils.nkprint(query, "debug")
  utils.nkprint("Changes = " .. self.db:changes(), "debug")
  if self.db:changes() == 0 then
    return "nickel.nochange"
  end
  return msg
end


function DatabaseManager:prepareAndExecute(query, ...)
  local stmt = self.db:prepare(query)
  if not stmt then
    error("Failed to prepare statement: " .. query)
  end

  -- Bind the values
  local args = {...}
  for i, value in ipairs(args) do
    stmt:bind(i, value)
  end

  -- Execute the statement
  local result = stmt:step()
  utils.nkprint(query, "debug")
  utils.nkprint("Changes = " .. self.db:changes(), "debug")
  if self.db:changes() == 0 then
    stmt:finalize()
    return "nickel.nochange"
  end

  -- Finalize the statement to release resources
  stmt:finalize()

  return result
end


function DatabaseManager:insertOrUpdateObject(tableName, object, canupdate)

  utils.nkprint("TABLENAME = " .. tableName, "debug")

  local columns = {}
  local values = {}
  local updateColumns = {}
  local columnsOrder = self:getTableColumnsName(tableName)
  local firstColumn
  -- Recherchez la première colonne non nulle et non vide
  for _, columnName in ipairs(columnsOrder) do
    if object[columnName] ~= nil and object[columnName] ~= "" then
      firstColumn = columnName
      break
    end
  end
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
  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s = ?", tableName, firstColumn)
  utils.nkprint(selectQuery, "debug")
  local count = 0
  local stmt = self.db:prepare(selectQuery)
  stmt:bind(1, object[firstColumn])
  for row in stmt:nrows() do
    count = tonumber(row["COUNT(*)"])
  end
  stmt:finalize()
  if count > 0 and canupdate then

      -- Suppose que le nom de la colonne qui identifie de manière unique la ligne est 'beammpid'.
      -- Update query with a placeholder for the WHERE clause
      local updateQuery = string.format("UPDATE %s SET %s WHERE %s = ?", tableName, table.concat(updateColumns, ", "), firstColumn)

      -- Execute the query using prepareAndExecute with the bound value for the WHERE clause
      return self:prepareAndExecute(updateQuery, object[firstColumn])
  else
    local placeholders = string.rep("?, ", #values - 1) .. "?" -- Generate placeholders like ?, ?, ?, ...
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), placeholders)
    
    -- Execute the query using prepareAndExecute with the values array
    return self:prepareAndExecute(insertQuery, table.unpack(values))
  end
end


function DatabaseManager:getEntry(class, columnName, columnValue)

  local tableName = class.tableName


  local query = string.format("SELECT * FROM %s WHERE %s = ?", tableName, columnName)
  local stmt = self.db:prepare(query)
  if not stmt then
    error("Failed to prepare statement: " .. query)
  end
  stmt:bind_values(columnValue)
  local results = {}
  for row in stmt:nrows() do
    table.insert(results, row)
    break
  end
  stmt:finalize()

  return results[1]
end

-- TODO IMPORTANT ! WHEN TRYING TO SYNC WE NEED TO MAKE SURE THE VERSION OF EVERY NICKEL IS THE SAME ! IF ITS NOT THE SAME AN ERROR OCCURS AND ASK TO UPDATE EVERY NICKEL AND THEN RESTART ! (AT THE RESTART IT WILL COMPARE EVERY DATABASE TO SYNC IF THERE IS PROBLEM)
-- TODO THE FUTUR AUTO UPDATE VAR IN THE CONFIG NEED TO BE THE SAME TO ACTIVATE THE SYNC
function DatabaseManager:deleteObject(class, conditions)
  local tableName = class.tableName

  if not conditions or #conditions == 0 then
      utils.nkprint("No conditions provided for deletion.", "error")
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
          
          self:returnQuery(alterQuery)
          -- self.db:exec(alterQuery)
        end
      end

    -- Ajoutez les colonnes manquantes
    for _, column in ipairs(columns) do
      local colName = column:match("^(%S+)")
      if not existingColumns[colName] then


        local alterQuery

        local isUnique = false
        if column:find("UNIQUE") ~= nil then
          column = column:gsub(" UNIQUE", "")
          isUnique = true
        end
        if column:find("NOT NULL") ~= nil then
          alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, column, "DEFAULT " .. class:getKey(column:match("^(%S+)%s")))
        else  
          alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s", tableName, column)
        end
        self:returnQuery(alterQuery)
        if isUnique then
          local query = string.format("CREATE UNIQUE INDEX idx_unique_%s ON %s(%s)", column:match("^(%S+)%s"), tableName, column:match("^(%S+)%s"))
          self:returnQuery(query)

        end
        -- self.db:exec(alterQuery)
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

function DatabaseManager:getAllClassByBeammpId(class, beammpid)
  local tableName = class.tableName
  local query = string.format("SELECT * FROM %s WHERE beammpid = %s", tableName, tostring(beammpid))
  local result = {}

  local i = 1
  for row in self.db:nrows(query) do
    result[i] = class.new();

  
    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = utils.string_to_table(value)
        result[i]:setKey(key, parsedList)
      else
        -- Utilisez une méthode set ou affectez directement les valeurs aux propriétés de la classe
        result[i]:setKey(key, value)  -- Assurez-vous que votre classe a une méthode set appropriée
      end
    end
    i = i + 1
  end


  return result
end





--- Get all users dynamically
---@param limit integer
---@param offset integer
---@param onlinePlayers table
-- function DatabaseManager:getUsersDynamically(limit, offset, onlinePlayers)
--   -- Get a set of online player beammpids
--   local onlineBeammpids = {}
--   for id, name in pairs(onlinePlayers) do
--     if not MP.IsPlayerGuest(id) then
--       local beammpid = tostring(utils.getPlayerBeamMPID(name))
--       onlineBeammpids[beammpid] = true
--     end
--   end
  

--   -- Create a list of beammpids for the SQL IN clause
--   local onlineBeammpidsList = {}
--   for beammpid in pairs(onlineBeammpids) do
--     table.insert(onlineBeammpidsList, "'" .. beammpid .. "'")
--   end
--   local onlineBeammpidsString = table.concat(onlineBeammpidsList, ", ")


--   local isNot;

--   if offset == 0 then
--     isNot = ""
--   else
--     isNot = "NOT"
--   end

--   -- Prepare the SQL query
--   local selectQuery = [[
--     SELECT Users.beammpid AS user_beammpid, Users.name, Users.whitelisted, Roles.roleName, Roles.permlvl, UsersStatus.*
--     FROM Users
--     JOIN UserRoles ON Users.beammpid = UserRoles.beammpid
--     JOIN Roles ON UserRoles.roleID = Roles.roleID
--     LEFT JOIN UsersStatus ON Users.beammpid = UsersStatus.beammpid
--     ORDER BY 
--       CASE WHEN Users.beammpid ]] .. isNot .. [[ IN (]] .. onlineBeammpidsString .. [[) THEN 0 ELSE 1 END, 
--       Roles.permlvl DESC, Users.name ASC
--     LIMIT ? OFFSET ?;
--   ]]

--   print(selectQuery)

--   local stmt = self.db:prepare(selectQuery)
--   stmt:bind(1, limit)
--   stmt:bind(2, offset)

--   local results = {}
  
--   for row in stmt:nrows() do
--     local user_id = row.user_beammpid
--     if not results[user_id] then
--       results[user_id] = {
--         roles = {},
--         status = {},
--         beammpid = row.user_beammpid,
--         name = row.name,
--         whitelisted = row.whitelisted,
--         online = onlineBeammpids[tostring(user_id)] or false, -- Add online status
--       }
--     end

--     table.insert(results[user_id].roles, {
--       name = row.roleName,
--       permlvl = row.permlvl,
--       -- Add any specific columns from UserRoles here
--     })

--     if row.status_type ~= nil then
--       table.insert(results[user_id].status, {
--         status_type = row.status_type,
--         status_value = row.is_status_value,
--         reason = row.reason,
--         time = row.time,
--         -- Add any specific columns from UsersStatus here
--       })
--     end
--   end
--   stmt:finalize()

--   -- Convert the dictionary to a list for final output
--   local final_results = {}
--   for _, user in pairs(results) do
--     table.insert(final_results, user)
--   end

--   return final_results
-- end

--- Get all users dynamically
---@param limit integer
---@param offset integer
---@param onlinePlayers table
function DatabaseManager:getUsersDynamically(limit, offset, onlinePlayers)
  -- Get a set of online player beammpids
  local onlineBeammpids = {}
  for id, name in pairs(onlinePlayers) do
    if not MP.IsPlayerGuest(id) then
      local beammpid = tostring(utils.getPlayerBeamMPID(name))
      onlineBeammpids[beammpid] = true
    end
  end

  -- Create a list of beammpids for the SQL IN clause
  local onlineBeammpidsList = {}
  for beammpid in pairs(onlineBeammpids) do
    table.insert(onlineBeammpidsList, "'" .. beammpid .. "'")
  end
  local onlineBeammpidsString = table.concat(onlineBeammpidsList, ", ")
  local onlineResults = {}
  -- Query to get all online users
  if offset == 0 then
    local onlineQuery = [[
      SELECT Users.beammpid AS user_beammpid, Users.name, Users.whitelisted, Roles.roleName, Roles.permlvl, UsersStatus.*
      FROM Users
      JOIN UserRoles ON Users.beammpid = UserRoles.beammpid
      JOIN Roles ON UserRoles.roleID = Roles.roleID
      LEFT JOIN UsersStatus ON Users.beammpid = UsersStatus.beammpid
      WHERE Users.beammpid IN (]] .. onlineBeammpidsString .. [[)
      ORDER BY Roles.permlvl DESC, Users.name ASC;
    ]]

    -- Fetch online users
    local stmtOnline = self.db:prepare(onlineQuery)
    for row in stmtOnline:nrows() do
      local user_id = row.user_beammpid
      if not onlineResults[user_id] then
        onlineResults[user_id] = {
          roles = {},
          status = {},
          beammpid = row.user_beammpid,
          name = row.name,
          whitelisted = row.whitelisted,
          online = true, -- Mark all as online
          b64img = "data:image/png;base64," .. online.getPlayerB64Img(row.user_beammpid, 40)
        }
      end

      -- Insert role
      table.insert(onlineResults[user_id].roles, {
        name = row.roleName,
        permlvl = row.permlvl,
      })

      -- Insert status if available
      if row.status_type ~= nil then
        table.insert(onlineResults[user_id].status, {
          status_type = row.status_type,
          status_value = row.is_status_value,
          reason = row.reason,
          time = row.time,
        })
      end
    end
    stmtOnline:finalize()
  end


  -- Query to get remaining users with pagination
  local remainingQuery = [[
    SELECT Users.beammpid AS user_beammpid, Users.name, Users.whitelisted, Roles.roleName, Roles.permlvl, UsersStatus.*
    FROM Users
    JOIN UserRoles ON Users.beammpid = UserRoles.beammpid
    JOIN Roles ON UserRoles.roleID = Roles.roleID
    LEFT JOIN UsersStatus ON Users.beammpid = UsersStatus.beammpid
    WHERE Users.beammpid NOT IN (]] .. table.concat(onlineBeammpidsList, ", ") .. [[)
    ORDER BY Roles.permlvl DESC, Users.name ASC
    LIMIT ? OFFSET ?;
  ]]

  -- Fetch remaining users
  local stmtRemaining = self.db:prepare(remainingQuery)
  stmtRemaining:bind(1, limit)
  stmtRemaining:bind(2, offset)

  local remainingResults = {}
  for row in stmtRemaining:nrows() do
    local user_id = row.user_beammpid
    if not onlineResults[user_id] then
      remainingResults[user_id] = {
        roles = {},
        status = {},
        beammpid = row.user_beammpid,
        name = row.name,
        whitelisted = row.whitelisted,
        online = false, -- Mark as offline
        b64img = "data:image/png;base64," .. online.getPlayerB64Img(row.user_beammpid, 40)
      }
    end

    -- Insert role
    table.insert(remainingResults[user_id].roles, {
      name = row.roleName,
      permlvl = row.permlvl,
    })

    -- Insert status if available
    if row.status_type ~= nil then
      table.insert(remainingResults[user_id].status, {
        status_type = row.status_type,
        status_value = row.is_status_value,
        reason = row.reason,
        time = row.time,
      })
    end
  end
  stmtRemaining:finalize()

  -- Combine results, with online users first
  local final_results = {}
  for _, user in pairs(onlineResults) do
    table.insert(final_results, user)
  end

  for _, user in pairs(remainingResults) do
    table.insert(final_results, user)
  end

  -- Return only the number of users specified by limit
  if limit then
    final_results = {table.unpack(final_results)}
  end

  return final_results
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
  utils.nkprint("Database opened", "debug")
  self.db = sqlite3.open(self.dbname)
end

function DatabaseManager:closeConnection()
  if self.db then
    utils.nkprint("Database closed", "debug")
    self.db:close()
    self.db = nil
  end
end
return DatabaseManager
