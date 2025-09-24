-- Database Management Class (Global Manager with MySQL/SQLite support)
DatabaseManager = {}

local config = {}

function DatabaseManager.init()
  local configDatabaseFile = ConfigManager.GetSetting("database").file
  local configDatabaseType = ConfigManager.GetSetting("database").type or "sqlite"

  -- Build configuration
  config.database_type = configDatabaseType

  if configDatabaseType == "mysql" then
    -- MySQL configuration
    config.mysql_host = ConfigManager.GetSetting("database").host or "localhost"
    config.mysql_port = ConfigManager.GetSetting("database").port or 3306
    config.mysql_database = ConfigManager.GetSetting("database").name or "nickel_beammp"
    config.mysql_username = ConfigManager.GetSetting("database").username or "root"
    config.mysql_password = ConfigManager.GetSetting("database").password or ""
    
    Utils.nkprint("Using MySQL database: " .. config.mysql_host .. ":" .. config.mysql_port .. "/" .. config.mysql_database, "info")
    
    -- Create adapter using factory
    if DatabaseFactory.validateConfig(config) then
      DatabaseManager.adapter = DatabaseFactory.createAdapter(config)
      DatabaseManager.db = DatabaseManager.adapter
    else
      error("Invalid MySQL configuration")
    end
  else
    -- SQLite configuration (fallback and default)
    if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
        config.database_file = Utils.script_path() .. configDatabaseFile
        DatabaseManager.dbname = config.database_file
        Utils.nkprint("Using custom SQLite database: " .. config.database_file, "info")
    else
        Utils.nkprint("No database set in config, using default SQLite path", "info") 
        config.database_file = Utils.script_path() .. "database/db.sqlite"
        DatabaseManager.dbname = config.database_file
    end
    

     
    DatabaseManager.adapter = DatabaseFactory.createAdapter(config)
    DatabaseManager.db = DatabaseManager.adapter

  end
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local processed = {}
  for _, col in ipairs(columns) do
    local trimmed = col:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" then
      table.insert(processed, trimmed)
    end
  end
    if config.database_type == "sqlite" then
      local sqliteParts = {}
      for _, raw in ipairs(columns) do
        local line = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
          local cleaned = line:gsub(",+$", "") -- gsub returns (str, count); avoid passing count to table.insert
          table.insert(sqliteParts, cleaned)
        end
      end
      local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(sqliteParts, ", "))
      Utils.nkprint("DDL(SQLite): " .. query, "info")
      local ok, err = pcall(function() DatabaseManager.db:exec(query) end)
      if not ok then
        error("Failed DDL (SQLite) for table " .. tableName .. ": " .. query .. " | " .. tostring(err))
      end
      return
    end

    local colDefs = {}
    local pkDefs = {}
    local fkDefs = {}
    local idxDefs = {}
    local otherConstraints = {}
    local hasAutoPK = {}

    local function quoteIdent(name)
      if not name then return name end
      if name:match("`") then return name end
      if name:match("^[A-Za-z0-9_]+$") then
        return "`" .. name .. "`"
      end
      return name
    end

    for _, raw in ipairs(columns) do
      local line = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
      if line ~= "" then
        line = line:gsub(",+$", "")
        local upper = line:upper()
          if upper:match("^FOREIGN KEY") then
            local colPart = line:match("FOREIGN KEY%s*%(([^)]+)%)") or ""
            local refTable, refCols = line:match("REFERENCES%s+([A-Za-z0-9_`]+)%s*%(([^)]+)%)")
            local rest = line:match("%)%s+REFERENCES[^(]+%([^)]*%)(.+)$") or ""
            local firstCol = colPart:match("[^,%s]+") or "fkcol"
            local constraintName
            if refTable then
              local cleanRef = refTable:gsub("`", "")
              constraintName = string.format("`fk_%s_%s_%s`", tableName, cleanRef, firstCol)
            else
              constraintName = string.format("`fk_%s_%s`", tableName, firstCol)
            end
            -- Quoter les listes de colonnes
            local function quoteCols(list)
              local out = {}
              for c in list:gmatch("[^,%s]+") do
                c = c:gsub("`", "")
                table.insert(out, quoteIdent(c))
              end
              return table.concat(out, ", ")
            end
            local fkColsQuoted = quoteCols(colPart)
            local refColsQuoted = refCols and quoteCols(refCols) or ""
            local refTableQuoted = refTable and quoteIdent(refTable:gsub("`", "")) or refTable or ""
            local rebuilt = string.format("CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s)%s", constraintName, fkColsQuoted, refTableQuoted, refColsQuoted, rest)
            table.insert(fkDefs, rebuilt)
        elseif upper:match("^PRIMARY KEY") then
          table.insert(pkDefs, line)
        else
          local colName, rest = line:match("^(%S+)%s+(.+)$")
          if colName and rest then
              local mapped = rest
              mapped = mapped:gsub("INTEGER PRIMARY KEY AUTOINCREMENT", "INT PRIMARY KEY AUTO_INCREMENT")
              mapped = mapped:gsub("INTEGER PRIMARY KEY", "INT PRIMARY KEY AUTO_INCREMENT")
              mapped = mapped:gsub("BOOLEAN", "TINYINT(1)")
              if mapped:find("PRIMARY KEY") then
                hasAutoPK[colName] = true
              end
              table.insert(colDefs, string.format("%s %s", quoteIdent(colName), mapped))
          else
            table.insert(otherConstraints, line)
          end
        end
      end
    end

    local seenIdx = {}
    for _, fk in ipairs(fkDefs) do
      local colList = fk:match("FOREIGN KEY%s*%(([^)]+)%)")
      if colList then
        for col in colList:gmatch("[^,%s]+") do
          local rawCol = col:gsub("`", "")
          if not hasAutoPK[rawCol] and not seenIdx[rawCol] then
            table.insert(idxDefs, string.format("KEY idx_%s_%s (%s)", tableName, rawCol, quoteIdent(rawCol)))
            seenIdx[rawCol] = true
          end
        end
      end
    end

    local parts = {}
    for _, v in ipairs(colDefs) do table.insert(parts, v) end
    for _, v in ipairs(pkDefs) do table.insert(parts, v) end
    for _, v in ipairs(idxDefs) do table.insert(parts, v) end
    for _, v in ipairs(otherConstraints) do table.insert(parts, v) end
    for _, v in ipairs(fkDefs) do table.insert(parts, v) end

    Utils.nkprint(string.format(
      "DDL(BuildDebug) table=%s colDefs=%d pk=%d idx=%d other=%d fk=%d firstPart='%s'",
      tableName, #colDefs, #pkDefs, #idxDefs, #otherConstraints, #fkDefs, parts[1] or "<nil>"
    ), "info")

    if (#colDefs == 0) and (#parts > 0) then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      Utils.nkprint("WARN: aucune définition de colonne détectée avant contraintes pour " .. tableName .. ", insertion colonne fallback.", "warn")
      table.insert(parts, 1, fallbackCol)
    elseif parts[1] and parts[1]:match("^FOREIGN KEY") then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      Utils.nkprint("WARN: première entrée est FOREIGN KEY pour " .. tableName .. ", ajout colonne fallback.", "warn")
      table.insert(parts, 1, fallbackCol)
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s) ENGINE=InnoDB", tableName, table.concat(parts, ", "))
    Utils.nkprint("DDL(MySQL): " .. query, "info")
    local ok, err = pcall(function() DatabaseManager.db:exec(query) end)
    if not ok then
      error("Failed DDL (MySQL) for table " .. tableName .. ": " .. query .. " | " .. tostring(err))
    end
end

function DatabaseManager:returnQuery(query)
  local msg = DatabaseManager.db:exec(query)
  Utils.nkprint(query, "debug")
  Utils.nkprint("Changes = " .. DatabaseManager.db:changes(), "debug")
  if msg == "nickel.nochange" then
    return msg
  end
  if DatabaseManager.db:changes() == 0 then
    return "nickel.nochange"
  end
  return 0
end

function DatabaseManager:prepareAndExecute(query, ...)
    local max_attempts = 3
    local delay_seconds = 100
    local attempts = 0
    
    while attempts < max_attempts do
        local stmt = DatabaseManager.db:prepare(query)
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
    Utils.nkprint(query, "debug")
    Utils.nkprint("Changes = " .. DatabaseManager.db:changes(), "debug")

    if result == 5 then -- SQLITE_BUSY (database locked)
            stmt:finalize()
            attempts = attempts + 1
            Utils.nkprint("Database locked, retrying (" .. attempts .. "/" .. max_attempts .. ")", "warn")
            MP.Sleep(delay_seconds)
        else
      local changes = DatabaseManager.db:changes()
      stmt:finalize()
      if changes == 0 then
        return "nickel.nochange"
      else
        return 0
      end
        end
    end
    
    -- If we get here, all attempts failed
    error("Failed to execute query after " .. max_attempts .. " attempts (database locked)")
end

function DatabaseManager:insertOrUpdateObject(tableName, object, canupdate)

  Utils.nkprint("TABLENAME = " .. tableName, "debug")
  object.tableName = nil
  local columns = {}
  local values = {}
  local updateColumns = {}
  local columnsOrder = DatabaseManager:getTableColumnsName(tableName)
  local firstColumn
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
      value = Utils.table_to_string(value)
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
  Utils.nkprint(selectQuery, "debug")
  local count = 0
  local stmt = DatabaseManager.db:prepare(selectQuery)
  stmt:bind(1, object[firstColumn])
  for row in stmt:nrows() do
    count = tonumber(row["COUNT(*)"])
  end
  stmt:finalize()
  if count > 0 and canupdate then

      -- Update query with a placeholder for the WHERE clause
      local updateQuery = string.format("UPDATE %s SET %s WHERE %s = ?", tableName, table.concat(updateColumns, ", "), firstColumn)

      -- Execute the query using prepareAndExecute with the bound value for the WHERE clause
      return DatabaseManager:prepareAndExecute(updateQuery, object[firstColumn])
  else
    local placeholders = string.rep("?, ", #values - 1) .. "?" -- Generate placeholders like ?, ?, ?, ...
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), placeholders)
    
    -- Execute the query using prepareAndExecute with the values array
    return DatabaseManager:prepareAndExecute(insertQuery, table.unpack(values))
  end
end


function DatabaseManager:getEntry(class, columnName, columnValue)

  local tableName = class.tableName


  local query = string.format("SELECT * FROM %s WHERE %s = ?", tableName, columnName)
  local stmt = DatabaseManager.db:prepare(query)
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
      Utils.nkprint("No conditions provided for deletion.", "error")
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
  
  return DatabaseManager:returnQuery(deleteQuery)

  -- TODO: Do that for every databases that need to be synced
end


function DatabaseManager:save(class, canupdate)
  if canupdate == nil then
    canupdate = true
  end
  local result = DatabaseManager:withConnection(function()
    local tableName = class.tableName
    return DatabaseManager:insertOrUpdateObject(tableName, class, canupdate)
  end)
  return result
end


function DatabaseManager:createTableForClass(class)

  local tableName = class.tableName
  local columns = class:getColumns()
  local existingColumns = DatabaseManager:getTableColumns(tableName)

  if not next(existingColumns) then
    DatabaseManager:createTableIfNotExists(tableName, columns)
  else
      local existingColumnsFinal = {}
      local columnsFinal = {}

      local foreignConstraints = {}

      for key2, _ in pairs(existingColumns) do
          table.insert(existingColumnsFinal, key2)
      end

      for key, column in ipairs(columns) do
        local colName = column:match("^(%S+)")
        if colName and colName:upper() == "FOREIGN" then
          table.insert(foreignConstraints, column)
        end
        local finalKey = Utils.get_key_for_value(existingColumnsFinal, colName)
        if finalKey ~= nil then
          columnsFinal[finalKey] = colName
        end
      end

      for key, column in ipairs(existingColumnsFinal) do

        if columnsFinal[key] == nil then
         
          local alterQuery = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, column)
          
          DatabaseManager:returnQuery(alterQuery)
          -- DatabaseManager.db:exec(alterQuery)
        end
      end

    -- Ajoutez les colonnes manquantes
    local pendingPrimaryKey = nil
    for _, rawcol in ipairs(columns) do
      local upper = rawcol:upper()
      if upper:match("^PRIMARY KEY") then
        pendingPrimaryKey = rawcol -- Ex: PRIMARY KEY (beammpid, roleID)
      end
    end

    for _, column in ipairs(columns) do
      local trimmed = column:gsub("^%s+", "")
      if trimmed:upper():match("^FOREIGN KEY") then
        goto continue_col_add
      end
      if trimmed:upper():match("^PRIMARY KEY") then
        goto continue_col_add
      end
      local colName = trimmed:match("^(%S+)")
      if not existingColumns[colName] then
        local working = trimmed
        local alterQuery
        local isUnique = false
        if working:find("UNIQUE") ~= nil then
          working = working:gsub(" UNIQUE", "")
          isUnique = true
        end
        if working:find("NOT NULL") ~= nil then
          alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s %s", tableName, working, "DEFAULT " .. tostring(class:getKey(working:match("^(%S+)%s")) or "''"))
        else
          alterQuery = string.format("ALTER TABLE %s ADD COLUMN %s", tableName, working)
        end
        Utils.nkprint("ALTER ADD COLUMN: " .. alterQuery, "info")
        DatabaseManager:returnQuery(alterQuery)
        if isUnique then
          local baseCol = working:match("^(%S+)%s")
          if baseCol then
            local query = string.format("CREATE UNIQUE INDEX idx_unique_%s ON %s(%s)", baseCol, tableName, baseCol)
            Utils.nkprint("CREATE UNIQUE INDEX: " .. query, "info")
            DatabaseManager:returnQuery(query)
          end
        end
        -- DatabaseManager.db:exec(alterQuery)
      end
      ::continue_col_add::
    end

    -- Ajout des FOREIGN KEY manquantes (MySQL uniquement pour l'instant)
    if config.database_type == "mysql" and #foreignConstraints > 0 then
      local existingCreate = ""
      for row in DatabaseManager.db:nrows("SHOW CREATE TABLE " .. tableName) do
        existingCreate = row["Create Table"] or ""
        break
      end
      for _, fkLine in ipairs(foreignConstraints) do
        local colPart = fkLine:match("FOREIGN KEY%s*%(([^)]+)%)") or ""
        local refTable, refCols = fkLine:match("REFERENCES%s+([A-Za-z0-9_`]+)%s*%(([^)]+)%)")
        if colPart ~= "" and refTable and refCols then
          local firstCol = colPart:match("[^,%s]+") or "fkcol"
          local cleanRef = refTable:gsub("`", "")
          local constraintName = string.format("fk_%s_%s_%s", tableName, cleanRef, firstCol)
          if not existingCreate:find(constraintName, 1, true) then
            -- Construire contrainte
            local function quoteCols(list)
              local out = {}
              for c in list:gmatch("[^,%s]+") do
                c = c:gsub("`", "")
                table.insert(out, "`" .. c .. "`")
              end
              return table.concat(out, ", ")
            end
            local fkColsQuoted = quoteCols(colPart)
            local refColsQuoted = quoteCols(refCols)
            local refTableQuoted = "`" .. cleanRef .. "`"
            local rest = fkLine:match("%)%s+REFERENCES[^(]+%([^)]*%)(.+)$") or ""
            local alterFk = string.format("ALTER TABLE %s ADD CONSTRAINT `%s` FOREIGN KEY (%s) REFERENCES %s(%s)%s", tableName, constraintName, fkColsQuoted, refTableQuoted, refColsQuoted, rest)
            Utils.nkprint("ALTER ADD FK: " .. alterFk, "info")
            local okFk, errFk = pcall(function() DatabaseManager.db:exec(alterFk) end)
            if not okFk then
              Utils.nkprint("Failed to add FK '" .. constraintName .. "': " .. tostring(errFk), "warn")
            end
          end
        end
      end
    end

    if config.database_type == "mysql" and pendingPrimaryKey then
      local hasPK = false
      for row in DatabaseManager.db:nrows("SHOW INDEX FROM " .. tableName .. " WHERE Key_name = 'PRIMARY'") do
        hasPK = true
        break
      end
      if not hasPK then
        local pkCols = pendingPrimaryKey:match("PRIMARY KEY%s*%(([^)]+)%)")
        if pkCols then
          local pkAlter = string.format("ALTER TABLE %s ADD PRIMARY KEY (%s)", tableName, pkCols)
          Utils.nkprint("ALTER ADD PRIMARY KEY: " .. pkAlter, "info")
          local okPk, errPk = pcall(function() DatabaseManager.db:exec(pkAlter) end)
          if not okPk then
            Utils.nkprint("Failed to add PRIMARY KEY on " .. tableName .. ": " .. tostring(errPk), "warn")
          end
        end
      end
    end
  end

end

function DatabaseManager:getAllEntry(class, conditions)
  local tableName = class.tableName
  local query = "SELECT * FROM " .. tableName

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
  Utils.nkprint("getAllEntry query: " .. query, "debug")
  
  local count = 0
  for row in DatabaseManager.db:nrows(query) do
    count = count + 1
    local result = class.new()

    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = Utils.string_to_table(value)
        result[key] = parsedList
      else
          result[key] = value
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

  for row in DatabaseManager.db:nrows(query) do
    result = class.new()

    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = Utils.string_to_table(value)
        result[key] = parsedList  -- Direct assignment instead of setKey
      else
        result[key] = value  -- Direct assignment instead of setKey
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
  for row in DatabaseManager.db:nrows(query) do
    -- Create new object instance
    local obj = class.new()
    
    -- Set all properties from database row
    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = Utils.string_to_table(value)
        obj[key] = parsedList  -- Direct assignment instead of setKey
      else
        obj[key] = value  -- Direct assignment instead of setKey
      end
    end
    
    -- Ensure tableName is set correctly
    obj.tableName = tableName
    
    result[i] = obj
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
--       local beammpid = tostring(Utils.getPlayerBeamMPID(name))
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

--   local stmt = DatabaseManager.db:prepare(selectQuery)
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
function DatabaseManager:getUsersDynamically(limit, offset, onlinePlayers, seeAdvancedUserInfos, allowbase64)
  -- Get a set of online player beammpids
  local onlineBeammpids = {}
  for id, name in pairs(onlinePlayers) do
    if not MP.IsPlayerGuest(id) then
      local beammpid = tostring(Utils.getPlayerBeamMPID(name))
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
      SELECT Users.beammpid AS user_beammpid, Users.name, Users.whitelisted, Roles.roleName, Roles.permlvl, UsersStatus.*, UserIps.ip
      FROM Users
      JOIN UserRoles ON Users.beammpid = UserRoles.beammpid
      JOIN Roles ON UserRoles.roleID = Roles.roleID
      LEFT JOIN UsersStatus ON Users.beammpid = UsersStatus.beammpid
      LEFT JOIN UserIps ON Users.beammpid = UserIps.beammpid
      WHERE Users.beammpid IN (]] .. onlineBeammpidsString .. [[)
      ORDER BY Roles.permlvl DESC, Users.name ASC;
    ]]

    -- Fetch online users
    local stmtOnline = DatabaseManager.db:prepare(onlineQuery)
    for row in stmtOnline:nrows() do
      local user_id = row.user_beammpid
      if not onlineResults[user_id] then
        onlineResults[user_id] = {
          roles = {},
          status = {},
          ips = {},
          beammpid = row.user_beammpid,
          name = row.name,
          whitelisted = row.whitelisted,
          online = true, -- Mark all as online
          b64img = allowbase64 and "data:image/png;base64," .. Online.getPlayerB64Img(row.user_beammpid) or nil
        }
      end

      -- Use hash tables to track existing roles, status, and IPs
      local rolesHash = {}
      for _, role in ipairs(onlineResults[user_id].roles) do
        rolesHash[role.name] = true
      end

      local statusHash = {}
      for _, status in ipairs(onlineResults[user_id].status) do
        statusHash[status.expiry_time] = true
      end

      local ipsHash = {}
      for _, ip in ipairs(onlineResults[user_id].ips) do
        ipsHash[ip] = true
      end

      -- Insert role if not already present
      if not rolesHash[row.roleName] then
        table.insert(onlineResults[user_id].roles, {
          name = row.roleName,
          permlvl = row.permlvl,
        })
        rolesHash[row.roleName] = true
      end

      -- Insert status if available and not already present
      if row.status_type ~= nil and not statusHash[row.expiry_time] then
        table.insert(onlineResults[user_id].status, {
          status_type = row.status_type,
          status_value = row.is_status_value,
          reason = row.reason,
          expiry_time = row.expiry_time,
        })
        statusHash[row.expiry_time] = true
      end

      -- Insert IP if available and not already present
      if seeAdvancedUserInfos and row.ip ~= nil and not ipsHash[row.ip] then
        table.insert(onlineResults[user_id].ips, row.ip)
        ipsHash[row.ip] = true
      end
    end
    stmtOnline:finalize()
  end

  -- Query to get remaining users with pagination
  local remainingQuery = [[
    SELECT Users.beammpid AS user_beammpid, Users.name, Users.whitelisted, Roles.roleName, Roles.permlvl, UsersStatus.*, UserIps.ip
    FROM Users
    JOIN UserRoles ON Users.beammpid = UserRoles.beammpid
    JOIN Roles ON UserRoles.roleID = Roles.roleID
    LEFT JOIN UsersStatus ON Users.beammpid = UsersStatus.beammpid
    LEFT JOIN UserIps ON Users.beammpid = UserIps.beammpid
    WHERE Users.beammpid NOT IN (]] .. table.concat(onlineBeammpidsList, ", ") .. [[)
    ORDER BY Roles.permlvl DESC, Users.name ASC
    LIMIT ? OFFSET ?;
  ]]

  -- Fetch remaining users
  local stmtRemaining = DatabaseManager.db:prepare(remainingQuery)
  stmtRemaining:bind(1, limit)
  stmtRemaining:bind(2, offset)

  local remainingResults = {}
  for row in stmtRemaining:nrows() do
    local user_id = row.user_beammpid
    if not remainingResults[user_id] then
      remainingResults[user_id] = {
        roles = {},
        status = {},
        ips = {},
        beammpid = row.user_beammpid,
        name = row.name,
        whitelisted = row.whitelisted,
        online = false, -- Mark as offline
        b64img = allowbase64 and "data:image/png;base64," .. Online.getPlayerB64Img(row.user_beammpid) or nil
      }
    end

    -- Use hash tables to track existing roles, status, and IPs
    local rolesHash = {}
    for _, role in ipairs(remainingResults[user_id].roles) do
      rolesHash[role.name] = true
    end

    local statusHash = {}
    for _, status in ipairs(remainingResults[user_id].status) do
      statusHash[status.expiry_time] = true
    end

    local ipsHash = {}
    for _, ip in ipairs(remainingResults[user_id].ips) do
      ipsHash[ip] = true
    end

    -- Insert role if not already present
    if not rolesHash[row.roleName] then
      table.insert(remainingResults[user_id].roles, {
        name = row.roleName,
        permlvl = row.permlvl,
      })
      rolesHash[row.roleName] = true
    end

    -- Insert status if available and not already present
    if row.status_type ~= nil and not statusHash[row.expiry_time] then
      table.insert(remainingResults[user_id].status, {
        status_type = row.status_type,
        status_value = row.is_status_value,
        reason = row.reason,
        expiry_time = row.expiry_time,
      })
      statusHash[row.expiry_time] = true
    end

    -- Insert IP if available and not already present
    if seeAdvancedUserInfos and row.ip ~= nil and not ipsHash[row.ip] then
      table.insert(remainingResults[user_id].ips, row.ip)
      ipsHash[row.ip] = true
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



--get an user with his roles and details like online, b64img but simple and return a json like getUsersDynamically return but only with one user
function DatabaseManager:getUserWithRoles(beammpid, permManager, allowbase64)
  local onlinePlayers = MP.GetPlayers()
  local user = DatabaseManager:getClassByBeammpId(User, beammpid)
  local userRoles = DatabaseManager:getAllClassByBeammpId(UserRole, beammpid)
  local userStatus = DatabaseManager:getAllClassByBeammpId(UserStatus, beammpid)
  local userIps = DatabaseManager:getAllClassByBeammpId(UserIp, beammpid)
  local userRolesFinal = {}
  local userStatusFinal = {}
  local userIpsFinal = {}

  for i, v in ipairs(userRoles) do
    table.insert(userRolesFinal, {
      name = role.roleName,
      permlvl = role.permlvl
    })
  end


  for i, v in ipairs(userStatus) do
    table.insert(userStatusFinal, {
      beammpid = beammpid,
      status_type = v.status_type,
      status_value = v.is_status_value,
      reason = v.reason,
      expiry_time = v.expiry_time
    })
  end

  for i, v in ipairs(userIps) do
    table.insert(userIpsFinal, v.ip)
  end

  local playerid = Utils.GetPlayerId(user.name)


    local userFinal = {
      roles = userRolesFinal,
      status = userStatusFinal,
      ips = userIpsFinal,
      beammpid = beammpid,
      name = user.name,
      whitelisted = user.whitelisted,
      online = onlinePlayers[playerid] ~= nil,
      b64img = allowbase64 and "data:image/png;base64," .. Online.getPlayerB64Img(beammpid) or nil
    }
    return userFinal
end
  
-- function DatabaseManager:likeSearchUserWithRoles(name, permManager)
--   local users = {}
--   local query = "SELECT * FROM users WHERE name LIKE ? LIMIT 50"
--   local stmt = DatabaseManager.db:prepare(query)
--   if not stmt then
--       error("Failed to prepare statement: " .. query)
--   end

--   -- Bind the values
--   stmt:bind_values("%" .. name .. "%")

--   -- Execute the statement and iterate over the results
--   for row in stmt:nrows() do
--       local user = DatabaseManager:getUserWithRoles(row.beammpid, permManager)
--       table.insert(users, user)
--   end

--   -- Finalize the statement to release resources
--   stmt:finalize()

--   return users
-- end



function DatabaseManager:getTableColumns(tableName)
  local existingColumns = {}
  local query
  
  if config.database_type == "sqlite" then
    query = string.format("PRAGMA table_info(%s)", tableName)
    for row in DatabaseManager.db:nrows(query) do
      existingColumns[row.name] = true
    end
  elseif config.database_type == "mysql" then
    query = string.format("SHOW COLUMNS FROM %s", tableName)
    for row in DatabaseManager.db:nrows(query) do
      existingColumns[row.Field] = true
    end
  end

  return existingColumns
end

function DatabaseManager:getTableColumnsName(tableName)
  local columns = {}
  local query
  if config.database_type == "sqlite" then
    query = "PRAGMA table_info(" .. tableName .. ")"
    for row in DatabaseManager.db:nrows(query) do
      table.insert(columns, row.name)
    end
  elseif config.database_type == "mysql" then
    query = "SHOW COLUMNS FROM " .. tableName
    for row in DatabaseManager.db:nrows(query) do
      table.insert(columns, row.Field)
    end
  end
  
  return columns
end


function DatabaseManager:openConnection()
  Utils.nkprint("Database opened", "debug")
  DatabaseManager.adapter:connect()

  -- For backward compatibility, expose the adapter as DatabaseManager.db
  DatabaseManager.db = DatabaseManager.adapter
end

function DatabaseManager:closeConnection()
  if DatabaseManager.adapter and DatabaseManager.adapter:isConnected() then
    Utils.nkprint("Database closed", "debug")
    DatabaseManager.adapter:disconnect()
    DatabaseManager.db = nil
  end
end
--return multiples values that can be anything
---@param callback function
---@return any ...
function DatabaseManager:withConnection(callback)
  local keepOpen = (DatabaseManager.database_type == "mysql")
  -- Always ensure connection before executing callback
  DatabaseManager:openConnection()
  local results = {pcall(callback)}
  -- For SQLite (and others) close immediately; for MySQL keep persistent
  if not keepOpen then
    DatabaseManager:closeConnection()
  end
  local ok = table.remove(results, 1)
  if not ok then
    -- If MySQL callback failed due to connection loss, attempt one retry
    local err = results[1]
    if keepOpen and type(err) == 'string' and (err:match("gone away") or err:match("Lost connection")) then
      Utils.nkprint("MySQL connection lost. Reconnecting and retrying once...", "warn")
      DatabaseManager:closeConnection() -- ensure clean state
      DatabaseManager:openConnection()
      results = {pcall(callback)}
      ok = table.remove(results, 1)
      if not ok then
        error(results[1])
      end
      return table.unpack(results)
    end
    error(err)
  end
  return table.unpack(results)
end


DatabaseManager.init()
