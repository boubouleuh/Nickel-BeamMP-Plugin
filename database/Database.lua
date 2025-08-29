local new = require("objects.New")
local utils = require("utils.misc")
local online = require("main.online")
local DatabaseFactory = require("database.adapters.DatabaseFactory")

local UserRoles = require("objects.UserRole")
local UsersStatus = require("objects.UserStatus")
local Users = require("objects.User")
local Roles = require("objects.Role")
local UserIp = require("objects.UserIp")

-- Database Management Class
---@class DatabaseManager
local DatabaseManager = {}

function DatabaseManager.new(config)
  assert(type(config) == "table", "DatabaseManager.new expects a configuration table")
  local self = {}

  local normalized = {
    database_type = config.database_type or config.type or "sqlite",
    database_file = config.database_file or config.file, -- sqlite
    mysql_host = config.mysql_host or config.host,
    mysql_port = config.mysql_port or config.port,
    mysql_database = config.mysql_database or config.name,
    mysql_username = config.mysql_username or config.username,
    mysql_password = config.mysql_password or config.password,
  }

  if normalized.database_type == "sqlite" and (not normalized.database_file or normalized.database_file == "") then
    normalized.database_file = "database/nickel.sqlite"
  end

  self.config = normalized

  if not DatabaseFactory.validateConfig(self.config) then
    error("Invalid database configuration")
  end

  self.adapter = DatabaseFactory.createAdapter(self.config)
  self.dbname = self.config.database_file or "database"
  return new._object(DatabaseManager, self)
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local processed = {}
  for _, col in ipairs(columns) do
    local trimmed = col:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed ~= "" then
      table.insert(processed, trimmed)
    end
  end
    if self.config.database_type == "sqlite" then
      local sqliteParts = {}
      for _, raw in ipairs(columns) do
        local line = (raw or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if line ~= "" then
          local cleaned = line:gsub(",+$", "") -- gsub returns (str, count); avoid passing count to table.insert
          table.insert(sqliteParts, cleaned)
        end
      end
      local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(sqliteParts, ", "))
      utils.nkprint("DDL(SQLite): " .. query, "info")
      local ok, err = pcall(function() self.db:exec(query) end)
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

    utils.nkprint(string.format(
      "DDL(BuildDebug) table=%s colDefs=%d pk=%d idx=%d other=%d fk=%d firstPart='%s'",
      tableName, #colDefs, #pkDefs, #idxDefs, #otherConstraints, #fkDefs, parts[1] or "<nil>"
    ), "info")

    if (#colDefs == 0) and (#parts > 0) then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      utils.nkprint("WARN: aucune définition de colonne détectée avant contraintes pour " .. tableName .. ", insertion colonne fallback.", "warn")
      table.insert(parts, 1, fallbackCol)
    elseif parts[1] and parts[1]:match("^FOREIGN KEY") then
      local fallbackCol = "`_dummy_id` INT PRIMARY KEY AUTO_INCREMENT"
      utils.nkprint("WARN: première entrée est FOREIGN KEY pour " .. tableName .. ", ajout colonne fallback.", "warn")
      table.insert(parts, 1, fallbackCol)
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s) ENGINE=InnoDB", tableName, table.concat(parts, ", "))
    utils.nkprint("DDL(MySQL): " .. query, "info")
    local ok, err = pcall(function() self.db:exec(query) end)
    if not ok then
      error("Failed DDL (MySQL) for table " .. tableName .. ": " .. query .. " | " .. tostring(err))
    end
end


function DatabaseManager:returnQuery(query)
  local msg = self.db:exec(query)
  utils.nkprint(query, "debug")
  utils.nkprint("Changes = " .. self.db:changes(), "debug")
  if msg == "nickel.nochange" then
    return msg
  end
  if self.db:changes() == 0 then
    return "nickel.nochange"
  end
  return 0
end


function DatabaseManager:prepareAndExecute(query, ...)
    local max_attempts = 3
    local delay_seconds = 100
    local attempts = 0
    
    while attempts < max_attempts do
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

    if result == 5 then -- SQLITE_BUSY (database locked)
            stmt:finalize()
            attempts = attempts + 1
            utils.nkprint("Database locked, retrying (" .. attempts .. "/" .. max_attempts .. ")", "warn")
            MP.Sleep(delay_seconds)
        else
      local changes = self.db:changes()
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

  utils.nkprint("TABLENAME = " .. tableName, "debug")
  object.tableName = nil
  local columns = {}
  local values = {}
  local updateColumns = {}
  local columnsOrder = self:getTableColumnsName(tableName)
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
  local result = self:withConnection(function()
    local tableName = class.tableName
    return self:insertOrUpdateObject(tableName, class, canupdate)
  end)
  return result
end

-- Dans la classe DatabaseManager

function DatabaseManager:createTableForClass(class)

  local tableName = class.tableName
  local columns = class:getColumns()
  local existingColumns = self:getTableColumns(tableName)

  if not next(existingColumns) then
    self:createTableIfNotExists(tableName, columns)
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
        local finalKey = utils.get_key_for_value(existingColumnsFinal, colName)
        if finalKey ~= nil then
          columnsFinal[finalKey] = colName
        end
      end

      for key, column in ipairs(existingColumnsFinal) do

        if columnsFinal[key] == nil then
         
          local alterQuery = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, column)
          
          self:returnQuery(alterQuery)
          -- self.db:exec(alterQuery)
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
        utils.nkprint("ALTER ADD COLUMN: " .. alterQuery, "info")
        self:returnQuery(alterQuery)
        if isUnique then
          local baseCol = working:match("^(%S+)%s")
          if baseCol then
            local query = string.format("CREATE UNIQUE INDEX idx_unique_%s ON %s(%s)", baseCol, tableName, baseCol)
            utils.nkprint("CREATE UNIQUE INDEX: " .. query, "info")
            self:returnQuery(query)
          end
        end
        -- self.db:exec(alterQuery)
      end
      ::continue_col_add::
    end

    -- Ajout des FOREIGN KEY manquantes (MySQL uniquement pour l'instant)
    if self.config.database_type == "mysql" and #foreignConstraints > 0 then
      local existingCreate = ""
      for row in self.db:nrows("SHOW CREATE TABLE " .. tableName) do
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
            utils.nkprint("ALTER ADD FK: " .. alterFk, "info")
            local okFk, errFk = pcall(function() self.db:exec(alterFk) end)
            if not okFk then
              utils.nkprint("Failed to add FK '" .. constraintName .. "': " .. tostring(errFk), "warn")
            end
          end
        end
      end
    end

    if self.config.database_type == "mysql" and pendingPrimaryKey then
      local hasPK = false
      for row in self.db:nrows("SHOW INDEX FROM " .. tableName .. " WHERE Key_name = 'PRIMARY'") do
        hasPK = true
        break
      end
      if not hasPK then
        local pkCols = pendingPrimaryKey:match("PRIMARY KEY%s*%(([^)]+)%)")
        if pkCols then
          local pkAlter = string.format("ALTER TABLE %s ADD PRIMARY KEY (%s)", tableName, pkCols)
          utils.nkprint("ALTER ADD PRIMARY KEY: " .. pkAlter, "info")
          local okPk, errPk = pcall(function() self.db:exec(pkAlter) end)
          if not okPk then
            utils.nkprint("Failed to add PRIMARY KEY on " .. tableName .. ": " .. tostring(errPk), "warn")
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
  result:setKey(key, value)
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
  result[i]:setKey(key, value)
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
---@param permManager PermissionsHandler
function DatabaseManager:getUsersDynamically(limit, offset, onlinePlayers, seeAdvancedUserInfos, allowbase64)
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
    local stmtOnline = self.db:prepare(onlineQuery)
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
          b64img = allowbase64 and "data:image/png;base64," .. online.getPlayerB64Img(row.user_beammpid) or nil
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
  local stmtRemaining = self.db:prepare(remainingQuery)
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
        b64img = allowbase64 and "data:image/png;base64," .. online.getPlayerB64Img(row.user_beammpid) or nil
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
  local user = self:getClassByBeammpId(Users, beammpid)
  local userRoles = self:getAllClassByBeammpId(UserRoles, beammpid)
  local userStatus = self:getAllClassByBeammpId(UsersStatus, beammpid)
  local userIps = self:getAllClassByBeammpId(UserIp, beammpid)
  local userRolesFinal = {}
  local userStatusFinal = {}
  local userIpsFinal = {}

  for i, v in ipairs(userRoles) do
  local role = self:getEntry(Roles, "roleID", v.roleID)
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

  local playerid = utils.GetPlayerId(user.name)


    local userFinal = {
      roles = userRolesFinal,
      status = userStatusFinal,
      ips = userIpsFinal,
      beammpid = beammpid,
      name = user.name,
      whitelisted = user.whitelisted,
      online = onlinePlayers[playerid] ~= nil,
      b64img = allowbase64 and "data:image/png;base64," .. online.getPlayerB64Img(beammpid) or nil
    }
    return userFinal
end
  
-- function DatabaseManager:likeSearchUserWithRoles(name, permManager)
--   local users = {}
--   local query = "SELECT * FROM users WHERE name LIKE ? LIMIT 50"
--   local stmt = self.db:prepare(query)
--   if not stmt then
--       error("Failed to prepare statement: " .. query)
--   end

--   -- Bind the values
--   stmt:bind_values("%" .. name .. "%")

--   -- Execute the statement and iterate over the results
--   for row in stmt:nrows() do
--       local user = self:getUserWithRoles(row.beammpid, permManager)
--       table.insert(users, user)
--   end

--   -- Finalize the statement to release resources
--   stmt:finalize()

--   return users
-- end



function DatabaseManager:getTableColumns(tableName)
  local existingColumns = {}
  local query
  
  if self.config.database_type == "sqlite" then
    query = string.format("PRAGMA table_info(%s)", tableName)
    for row in self.db:nrows(query) do
      existingColumns[row.name] = true
    end
  elseif self.config.database_type == "mysql" then
    query = string.format("SHOW COLUMNS FROM %s", tableName)
    for row in self.db:nrows(query) do
      existingColumns[row.Field] = true
    end
  end

  return existingColumns
end

function DatabaseManager:getTableColumnsName(tableName)
  local columns = {}
  local query
  
  if self.config.database_type == "sqlite" then
    query = "PRAGMA table_info(" .. tableName .. ")"
    for row in self.db:nrows(query) do
      table.insert(columns, row.name)
    end
  elseif self.config.database_type == "mysql" then
    query = "SHOW COLUMNS FROM " .. tableName
    for row in self.db:nrows(query) do
      table.insert(columns, row.Field)
    end
  end
  
  return columns
end


function DatabaseManager:openConnection()
  utils.nkprint("Database opened", "debug")
  self.adapter:connect()
  -- For backward compatibility, expose the adapter as self.db
  self.db = self.adapter
end

function DatabaseManager:closeConnection()
  if self.adapter and self.adapter:isConnected() then
    utils.nkprint("Database closed", "debug")
    self.adapter:disconnect()
    self.db = nil
  end
end

function DatabaseManager:withConnection(callback)
  local keepOpen = (self.config.database_type == "mysql")
  -- Always ensure connection before executing callback
  self:openConnection()
  local results = {pcall(callback)}
  -- For SQLite (and others) close immediately; for MySQL keep persistent
  if not keepOpen then
    self:closeConnection()
  end
  local ok = table.remove(results, 1)
  if not ok then
    -- If MySQL callback failed due to connection loss, attempt one retry
    local err = results[1]
    if keepOpen and type(err) == 'string' and (err:match("gone away") or err:match("Lost connection")) then
      utils.nkprint("MySQL connection lost. Reconnecting and retrying once...", "warn")
      self:closeConnection() -- ensure clean state
      self:openConnection()
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

return DatabaseManager
