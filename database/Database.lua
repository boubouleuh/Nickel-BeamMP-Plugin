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

function DatabaseManager:createTableIfNotExists(class)
  -- Register class for final schema sync
  if not DatabaseManager.registeredClasses then DatabaseManager.registeredClasses = {} end
  local found = false
  for _, c in ipairs(DatabaseManager.registeredClasses) do
    if c.tableName == class.tableName then found = true break end
  end
  if not found then table.insert(DatabaseManager.registeredClasses, class) end

  local tableName = class.tableName
  local columns = class:getColumns()

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
      local query = string.format('CREATE TABLE IF NOT EXISTS "%s" (%s)', tableName, table.concat(sqliteParts, ", "))
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

    if (#colDefs == 0) and (#parts > 0) then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      table.insert(parts, 1, fallbackCol)
    elseif parts[1] and parts[1]:match("^FOREIGN KEY") then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      table.insert(parts, 1, fallbackCol)
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s) ENGINE=InnoDB", tableName, table.concat(parts, ", "))
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
    local delay_ms = 100
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
            MP.Sleep(delay_ms)
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

--- Prepare a SELECT query, bind values, return all rows as an array
---@param query string The SQL query with ? placeholders
---@param ... any Bind values
---@return table[] Array of row tables
function DatabaseManager:prepareAndSelect(query, ...)
    local stmt = DatabaseManager.db:prepare(query)
    if not stmt then
        error("Failed to prepare statement: " .. query)
    end
    local args = {...}
    if #args > 0 then
        stmt:bind_values(table.unpack(args))
    end
    local rows = {}
    for row in stmt:nrows() do
        table.insert(rows, row)
    end
    stmt:finalize()
    return rows
end

-- Cache for table columns to avoid repeated schema queries
DatabaseManager.columnTypesCache = {}

function DatabaseManager:getColumnType(class, colName)
    local tableName = class.tableName
    if not DatabaseManager.columnTypesCache[tableName] then
        DatabaseManager.columnTypesCache[tableName] = {}
        local columns = class:getColumns()
        for _, raw in ipairs(columns) do
            local name, rest = raw:match("^(%S+)%s+(.+)$")
            if name then
                name = name:gsub("`", "")
                local upperRest = rest:upper()
                if upperRest:find("INT") or upperRest:find("DECIMAL") or upperRest:find("DOUBLE") or upperRest:find("FLOAT") or upperRest:find("NUMERIC") then
                   DatabaseManager.columnTypesCache[tableName][name] = "number"
                elseif upperRest:find("BOOL") then
                   DatabaseManager.columnTypesCache[tableName][name] = "boolean"
                else
                   DatabaseManager.columnTypesCache[tableName][name] = "string"
                end
            end
        end
    end
    return DatabaseManager.columnTypesCache[tableName][colName]
end

function DatabaseManager:mapRowToClass(class, row)
    if not row then return nil end
    local instance = class.new()
    
    for key, value in pairs(row) do
        local targetType = DatabaseManager:getColumnType(class, key)
        -- Fallback to instance default type if available
        if not targetType and instance[key] ~= nil then
             targetType = type(instance[key])
        end
        
        if targetType == "number" then
            instance[key] = tonumber(value) or value
        elseif targetType == "boolean" then
            if type(value) == "string" then
                if value == "1" or value == "true" then instance[key] = true
                else instance[key] = false end
            elseif type(value) == "number" then
                instance[key] = (value ~= 0)
            else
                instance[key] = value
            end
        -- Handle table parsing
        elseif type(value) == "string" and value:find("^{") then
            instance[key] = Utils.string_to_table(value)
        else
            instance[key] = value
        end
    end
    -- Keep tableName
    instance.tableName = class.tableName
    return instance
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
  local updatePlaceholders = {}
  for key, value in pairs(object) do
    table.insert(columns, key)
    if type(value) == "table" then
      value = Utils.table_to_string(value)
    elseif type(value) == "boolean" then
      value = value and 1 or 0
    end

    table.insert(values, value)
    table.insert(updatePlaceholders, string.format("%s = ?", key))
  end
  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s = ?", tableName, firstColumn)
  Utils.nkprint(selectQuery, "debug")
  local rows = DatabaseManager:prepareAndSelect(selectQuery, object[firstColumn])
  local count = rows[1] and tonumber(rows[1]["COUNT(*)"]) or 0
  if count > 0 and canupdate then

      -- Update query with a placeholder for the WHERE clause
      local updateQuery = string.format("UPDATE %s SET %s WHERE %s = ?", tableName, table.concat(updatePlaceholders, ", "), firstColumn)

      -- Execute the query using prepareAndExecute with bound values (all columns) and the WHERE value appended
      local params = {}
      for _, v in ipairs(values) do table.insert(params, v) end
      table.insert(params, object[firstColumn])
      return DatabaseManager:prepareAndExecute(updateQuery, table.unpack(params))
  else
    local placeholders = string.rep("?, ", #values - 1) .. "?" -- Generate placeholders like ?, ?, ?, ...
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), placeholders)
    
    -- Execute the query using prepareAndExecute with the values array
    return DatabaseManager:prepareAndExecute(insertQuery, table.unpack(values))
  end
end


function DatabaseManager:getEntry(class, columnName, columnValue)
  local query = string.format("SELECT * FROM %s WHERE %s = ?", class.tableName, columnName)
  local rows = DatabaseManager:prepareAndSelect(query, columnValue)
  return rows[1] and DatabaseManager:mapRowToClass(class, rows[1]) or nil
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
  local bindValues = {}
  for i, condition in ipairs(conditions) do
      local columnName, columnValue = condition[1], condition[2]
      table.insert(whereClauses, columnName .. " = ?")
      table.insert(bindValues, columnValue)
  end

  local whereClauseString = table.concat(whereClauses, " AND ")
  local deleteQuery = string.format("DELETE FROM %s WHERE %s", tableName, whereClauseString)

  return DatabaseManager:prepareAndExecute(deleteQuery, table.unpack(bindValues))

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

local function normalizeSQL(sql)
  if not sql then return "" end
  local s = sql
  s = s:gsub("IF%s+NOT%s+EXISTS%s*", "")
  s = s:gsub('"', '')
  s = s:gsub("[\r\n\t]+", " ")
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  s = s:upper()
  return s
end

local function buildExpectedCreateSQL(tableName, columns)
  local parts = {}
  for _, raw in ipairs(columns) do
    local line = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      local cleaned = line:gsub(",+$", "")
      table.insert(parts, cleaned)
    end
  end
  return string.format('CREATE TABLE "%s" (%s)', tableName, table.concat(parts, ", "))
end

local function quoteTable(name)
  return '"' .. name:gsub('"', '""') .. '"'
end

local tableColumnsCache = {}

local function syncSchemaForClass(class, allowDrop)
  local tableName = class.tableName
  local columns = class:getColumns()
  local quoted = quoteTable(tableName)

  if config.database_type == "sqlite" then
    local currentSQL = nil
    local stmt = DatabaseManager.db:prepare(string.format("SELECT sql FROM sqlite_master WHERE type='table' AND name='%s'", tableName))
    if stmt then
      for row in stmt:nrows() do
        currentSQL = row.sql
      end
      stmt:finalize()
    end
    if not currentSQL then return end

    local expectedSQL = buildExpectedCreateSQL(tableName, columns)
    local normalizedCurrent = normalizeSQL(currentSQL)
    local normalizedExpected = normalizeSQL(expectedSQL)

    if normalizedCurrent == normalizedExpected then return end

    Utils.nkprint("Schema change detected for table " .. tableName .. ", rebuilding...", "info")
    Utils.nkprint("Current:  " .. normalizedCurrent, "debug")
    Utils.nkprint("Expected: " .. normalizedExpected, "debug")

    local newColumnNames = {}
    for _, col in ipairs(columns) do
      local colName = col:match("^(%S+)")
      if colName then
        local u = colName:upper()
        if u ~= "FOREIGN" and u ~= "PRIMARY" and u ~= "UNIQUE"
            and u ~= "CHECK" and u ~= "CONSTRAINT" then
          table.insert(newColumnNames, colName)
        end
      end
    end

    local oldColumnNames = {}
    for row in DatabaseManager.db:nrows(string.format("PRAGMA table_info(%s)", quoted)) do
      table.insert(oldColumnNames, row.name)
    end

    local oldSet = {}
    for _, name in ipairs(oldColumnNames) do oldSet[name] = true end
    local commonColumns = {}
    for _, name in ipairs(newColumnNames) do
      if oldSet[name] then
        table.insert(commonColumns, name)
      end
    end

    local rebuildName = tableName .. "_nk_rebuild"
    local rebuildQuoted = quoteTable(rebuildName)
    local rebuildSQL = buildExpectedCreateSQL(rebuildName, columns)

    DatabaseManager.db:exec("PRAGMA foreign_keys=OFF")
    DatabaseManager.db:exec("BEGIN TRANSACTION")

    local function sqliteExec(sql)
      local rc = DatabaseManager.db:exec(sql)
      if rc ~= SQLITE3.OK then
        error("SQL error " .. rc .. " on: " .. sql)
      end
    end

    local rebuildOk, rebuildErr = pcall(function()
      sqliteExec(string.format("DROP TABLE IF EXISTS %s", rebuildQuoted))
      sqliteExec(rebuildSQL)
      if #commonColumns > 0 then
        local colStr = table.concat(commonColumns, ", ")
        sqliteExec(string.format("INSERT INTO %s (%s) SELECT %s FROM %s", rebuildQuoted, colStr, colStr, quoted))
      end
      sqliteExec(string.format("DROP TABLE %s", quoted))
      sqliteExec(string.format("ALTER TABLE %s RENAME TO %s", rebuildQuoted, quoted))
    end)

    if rebuildOk then
      DatabaseManager.db:exec("COMMIT")
      Utils.nkprint("Table " .. tableName .. " rebuilt successfully.", "info")
    else
      DatabaseManager.db:exec("ROLLBACK")
      DatabaseManager.db:exec(string.format("DROP TABLE IF EXISTS %s", rebuildQuoted))
      Utils.nkprint("Failed to rebuild table " .. tableName .. ": " .. tostring(rebuildErr), "error")
    end

    DatabaseManager.db:exec("PRAGMA foreign_keys=ON")
    DatabaseManager.columnTypesCache[tableName] = nil
    tableColumnsCache[tableName] = nil
    return
  end

  local existingColumns = DatabaseManager:getTableColumns(tableName)
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

  -- Drop unused columns
  if allowDrop then
    Utils.nkprint("Syncing schema for " .. tableName .. ". DB Columns: " .. table.concat(existingColumnsFinal, ", "), "debug")
    for key, column in ipairs(existingColumnsFinal) do
      if columnsFinal[key] == nil then
        local alterQuery = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, column)
        Utils.nkprint("Dropping unused column " .. column .. " from table " .. tableName, "info")
        DatabaseManager:returnQuery(alterQuery)
      end
    end
  end

  -- Add missing columns
  local pendingPrimaryKey = nil
  for _, rawcol in ipairs(columns) do
    local upper = rawcol:upper()
    if upper:match("^PRIMARY KEY") then
      pendingPrimaryKey = rawcol
    end
  end

  for _, column in ipairs(columns) do
    local trimmed = column:gsub("^%s+", "")
    if trimmed:upper():match("^FOREIGN KEY") or trimmed:upper():match("^PRIMARY KEY") then
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
      DatabaseManager:returnQuery(alterQuery)
      if isUnique then
        local baseCol = working:match("^(%S+)%s")
        if baseCol then
          local query = string.format("CREATE UNIQUE INDEX idx_unique_%s ON %s(%s)", baseCol, tableName, baseCol)
          DatabaseManager:returnQuery(query)
        end
      end
    end
    ::continue_col_add::
  end

  if #foreignConstraints > 0 then
    local existingCreate = ""
    for row in DatabaseManager.db:nrows("SHOW CREATE TABLE " .. tableName) do
      existingCreate = row["Create Table"] or ""
      break
    end

    local function quoteCols(list)
      local out = {}
      for c in list:gmatch("[^,%s]+") do
        c = c:gsub("`", "")
        table.insert(out, "`" .. c .. "`")
      end
      return table.concat(out, ", ")
    end

    for _, fkLine in ipairs(foreignConstraints) do
      local colPart = fkLine:match("FOREIGN KEY%s*%(([^)]+)%)") or ""
      local refTable, refCols = fkLine:match("REFERENCES%s+([A-Za-z0-9_`]+)%s*%(([^)]+)%)")
      if colPart ~= "" and refTable and refCols then
        local firstCol = colPart:match("[^,%s]+") or "fkcol"
        local cleanRef = refTable:gsub("`", "")
        local constraintName = string.format("fk_%s_%s_%s", tableName, cleanRef, firstCol)
        local fkColsQuoted = quoteCols(colPart)
        local refColsQuoted = quoteCols(refCols)
        local refTableQuoted = "`" .. cleanRef .. "`"
        local rest = fkLine:match("%)%s+REFERENCES[^(]+%([^)]*%)(.+)$") or ""

        if not existingCreate:find(constraintName, 1, true) then
          local alterFk = string.format("ALTER TABLE %s ADD CONSTRAINT `%s` FOREIGN KEY (%s) REFERENCES %s(%s)%s",
            tableName, constraintName, fkColsQuoted, refTableQuoted, refColsQuoted, rest)
          local okFk, errFk = pcall(function() DatabaseManager.db:exec(alterFk) end)
          if not okFk then
            Utils.nkprint("Failed to add FK '" .. constraintName .. "': " .. tostring(errFk), "debug")
          end
        else
          local expectedRest = fkLine:match("REFERENCES%s+[^(]+%([^)]*%)(.*)$") or ""
          local existingFkLine = existingCreate:match("CONSTRAINT%s+`" .. constraintName .. "`[^\n,]+") or ""
          local existingRest = existingFkLine:match("REFERENCES%s+[^(]+%([^)]*%)(.*)$") or ""

          if normalizeSQL(expectedRest) ~= normalizeSQL(existingRest) then
            pcall(function()
              DatabaseManager.db:exec(string.format("ALTER TABLE %s DROP FOREIGN KEY `%s`", tableName, constraintName))
            end)
            local addFk = string.format("ALTER TABLE %s ADD CONSTRAINT `%s` FOREIGN KEY (%s) REFERENCES %s(%s)%s",
              tableName, constraintName, fkColsQuoted, refTableQuoted, refColsQuoted, rest)
            local okFk, errFk = pcall(function() DatabaseManager.db:exec(addFk) end)
            if not okFk then
              Utils.nkprint("Failed to update FK '" .. constraintName .. "': " .. tostring(errFk), "debug")
            end
          end
        end
      end
    end
  end

  -- Handle missing PK
  if pendingPrimaryKey then
    local hasPK = false
    for row in DatabaseManager.db:nrows("SHOW INDEX FROM " .. tableName .. " WHERE Key_name = 'PRIMARY'") do
      hasPK = true
      break
    end
    if not hasPK then
      local pkCols = pendingPrimaryKey:match("PRIMARY KEY%s*%(([^)]+)%)")
      if pkCols then
        local pkAlter = string.format("ALTER TABLE %s ADD PRIMARY KEY (%s)", tableName, pkCols)
        local okPk, errPk = pcall(function() DatabaseManager.db:exec(pkAlter) end)
        if not okPk then
          Utils.nkprint("Failed to add PRIMARY KEY on " .. tableName .. ": " .. tostring(errPk), "debug")
        end
      end
    end
  end

  -- Invalidate caches after MySQL schema changes
  DatabaseManager.columnTypesCache[tableName] = nil
  tableColumnsCache[tableName] = nil
end

---Extend a database table with new columns dynamically
---@param class table The object class (e.g. User)
---@param newColumns table List of column definitions (e.g. {"money INTEGER DEFAULT 0"})
function DatabaseManager:extendTable(class, newColumns)
  if not class or not class.getColumns then
    Utils.nkprint("Invalid class provided to extendTable", "error")
    return
  end

  -- Initialize extension storage if needed
  if not class._extendedColumns then
    class._extendedColumns = {}
    
    -- Hook getColumns only once
    local originalGetColumns = class.getColumns
    class.getColumns = function()
      local columns = originalGetColumns()
      for _, col in ipairs(class._extendedColumns) do
        table.insert(columns, col)
      end
      return columns
    end
  end

  -- Add new columns if they don't exist
  for _, newCol in ipairs(newColumns) do
    local exists = false
    for _, existing in ipairs(class._extendedColumns) do
      if existing == newCol then 
        exists = true 
        break 
      end
    end
    
    if not exists then
      table.insert(class._extendedColumns, newCol)
    end
  end

  -- Apply schema changes
  DatabaseManager:withConnection(function()
    DatabaseManager:createTableIfNotExists(class)
    syncSchemaForClass(class, false)
  end)
end

---Add a column by inferring type from a default value
---@param class table The object class
---@param name string Column name
---@param defaultValue any The default value (used to infer type)
function DatabaseManager:addColumn(class, name, defaultValue)
  local colType = "VARCHAR(255)" -- Default fallback
  local valType = type(defaultValue)
  
  if valType == "number" then
    -- Check if integer
    if math.type then -- Lua 5.3+
      if math.type(defaultValue) == "integer" then
        colType = "INTEGER"
      else
        colType = "DOUBLE"
      end
    else
      -- Fallback for older Lua or if math.type not available
      if defaultValue % 1 == 0 then
        colType = "INTEGER"
      else
        colType = "DOUBLE"
      end
    end
  elseif valType == "boolean" then
    colType = "BOOLEAN"
  elseif valType == "string" then
    colType = "VARCHAR(255)"
  end

  -- Use the existing extendTable with the table format
  -- We construct the column definition manually
  local colDef = string.format("%s %s DEFAULT %s", name, colType, tostring(defaultValue))
  
  -- Handle string quoting for default value
  if valType == "string" then
    colDef = string.format("%s %s DEFAULT '%s'", name, colType, defaultValue)
  end

  DatabaseManager:extendTable(class, {colDef})
end

function DatabaseManager:getAllEntry(class, conditions)
  local tableName = class.tableName
  local query = "SELECT * FROM " .. tableName
  -- Support two formats for conditions:
  -- 1) Array of pairs: {{"col", val}, {"col2", val2}}
  -- 2) Associative table: {col = val, col2 = val2}
  local whereClauses = {}
  local bindValues = {}
  if conditions and type(conditions) == "table" then
    -- If indexed array (list of pairs)
    if conditions[1] ~= nil then
      for i, condition in ipairs(conditions) do
        local columnName, columnValue = condition[1], condition[2]
        if type(columnValue) == "boolean" then columnValue = columnValue and 1 or 0 end
        table.insert(whereClauses, columnName .. " = ?")
        table.insert(bindValues, columnValue)
      end
    else
      -- Associative table
      for columnName, columnValue in pairs(conditions) do
        if type(columnValue) == "boolean" then columnValue = columnValue and 1 or 0 end
        table.insert(whereClauses, columnName .. " = ?")
        table.insert(bindValues, columnValue)
      end
    end
  end

  if #whereClauses > 0 then
    local whereClauseString = table.concat(whereClauses, " AND ")
    query = query .. " WHERE " .. whereClauseString
  end

  local rows = DatabaseManager:prepareAndSelect(query, table.unpack(bindValues))
  local results = {}
  for _, row in ipairs(rows) do
    table.insert(results, DatabaseManager:mapRowToClass(class, row))
  end
  return results
end




function DatabaseManager:getClassByBeammpId(class, beammpid)
  local query = string.format("SELECT * FROM %s WHERE beammpid = ? LIMIT 1", class.tableName)
  local rows = DatabaseManager:prepareAndSelect(query, tostring(beammpid))
  return rows[1] and DatabaseManager:mapRowToClass(class, rows[1]) or nil
end

function DatabaseManager:getAllClassByBeammpId(class, beammpid)
  local query = string.format("SELECT * FROM %s WHERE beammpid = ?", class.tableName)
  local rows = DatabaseManager:prepareAndSelect(query, tostring(beammpid))
  local result = {}
  for i, row in ipairs(rows) do
    result[i] = DatabaseManager:mapRowToClass(class, row)
  end
  return result
end

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
  local onlineBeammpidValues = {}
  for beammpid in pairs(onlineBeammpids) do
    table.insert(onlineBeammpidsList, "?")
    table.insert(onlineBeammpidValues, beammpid)
  end
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
      WHERE Users.beammpid IN (]] .. table.concat(onlineBeammpidsList, ", ") .. [[)
      ORDER BY Roles.permlvl DESC, Users.name ASC;
    ]]

    -- Fetch online users
    local onlineRows = DatabaseManager:prepareAndSelect(onlineQuery, table.unpack(onlineBeammpidValues))
    for _, row in ipairs(onlineRows) do
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
  local remainingBindArgs = {}
  for _, val in ipairs(onlineBeammpidValues) do table.insert(remainingBindArgs, val) end
  table.insert(remainingBindArgs, limit)
  table.insert(remainingBindArgs, offset)
  local remainingRows = DatabaseManager:prepareAndSelect(remainingQuery, table.unpack(remainingBindArgs))

  local remainingResults = {}
  for _, row in ipairs(remainingRows) do
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
      name = v.roleName,
      permlvl = v.permlvl
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
  if tableColumnsCache[tableName] then
    return tableColumnsCache[tableName]
  end

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
  
  tableColumnsCache[tableName] = columns
  return columns
end


function DatabaseManager:openConnection()
  if not DatabaseManager._connectionDepth then DatabaseManager._connectionDepth = 0 end
  DatabaseManager._connectionDepth = DatabaseManager._connectionDepth + 1
  if DatabaseManager._connectionDepth == 1 then
    Utils.nkprint("Database opened", "debug")
    DatabaseManager.adapter:connect()
    DatabaseManager.db = DatabaseManager.adapter
  end
end

function DatabaseManager:closeConnection()
  if not DatabaseManager._connectionDepth or DatabaseManager._connectionDepth <= 0 then return end
  DatabaseManager._connectionDepth = DatabaseManager._connectionDepth - 1
  if DatabaseManager._connectionDepth == 0 then
    if DatabaseManager.adapter and DatabaseManager.adapter:isConnected() then
      Utils.nkprint("Database closed", "debug")
      DatabaseManager.adapter:disconnect()
      DatabaseManager.db = nil
    end
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

function DatabaseManager:syncSchemas()
  if not DatabaseManager.registeredClasses then return end
  DatabaseManager:withConnection(function()
    for _, class in ipairs(DatabaseManager.registeredClasses) do
      syncSchemaForClass(class, true)
    end
  end)
end


DatabaseManager.init()
