-- Database Management Class
DatabaseManager = {}

function DatabaseManager.init()
  local configDatabaseFile = ConfigManager.GetSetting("sync").database_file

  if configDatabaseFile ~= "" and configDatabaseFile ~= nil then
      DatabaseManager.dbname = configDatabaseFile
      Utils.nkprint("Using custom database: " .. configDatabaseFile, "info")
  else
      Utils.nkprint("No database set in config, now using default path", "info") 
      DatabaseManager.dbname = Utils.script_path() .. "database/db.sqlite"
  end
end

function DatabaseManager:createTableIfNotExists(tableName, columns)
  local query = string.format("CREATE TABLE IF NOT EXISTS %s (%s)", tableName, table.concat(columns, ", "))

  DatabaseManager.db:exec(query)
end


function DatabaseManager:returnQuery(query)
  local msg = DatabaseManager.db:exec(query)
  Utils.nkprint(query, "debug")
  Utils.nkprint("Changes = " .. DatabaseManager.db:changes(), "debug")
  if DatabaseManager.db:changes() == 0 then
    return "nickel.nochange"
  end
  return msg
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
            -- Normal processing
            if DatabaseManager.db:changes() == 0 then
                stmt:finalize()
                return "nickel.nochange"
            end
            
            stmt:finalize()
            return result
        end
    end
    
    -- If we get here, all attempts failed
    error("Failed to execute query after " .. max_attempts .. " attempts (database locked)")
end


function DatabaseManager:getTablePrimaryKeyColumns(tableName)
    local query = string.format("PRAGMA table_info(%s)", tableName)
    local primaryKeys = {}
    
    for row in DatabaseManager.db:nrows(query) do
        if row.pk and row.pk > 0 then  -- pk > 0 means it's part of primary key
            table.insert(primaryKeys, row.name)
        end
    end
    
    return primaryKeys
end

function DatabaseManager:insertOrUpdateObject(tableName, object, canupdate)

  Utils.nkprint("TABLENAME = " .. tableName, "debug")
  object.tableName = nil
  local columns = {}
  local values = {}
  local columnsOrder = DatabaseManager:getTableColumnsName(tableName)
  
  -- Get primary key columns to build proper WHERE clause
  local primaryKeyColumns = DatabaseManager:getTablePrimaryKeyColumns(tableName)
  
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
  end
  
  -- Build WHERE clause based on primary key columns
  local whereConditions = {}
  local whereValues = {}
  for _, pkColumn in ipairs(primaryKeyColumns) do
    if object[pkColumn] ~= nil then
      table.insert(whereConditions, pkColumn .. " = ?")
      table.insert(whereValues, object[pkColumn])
    end
  end
  
  -- If no primary key columns found, fall back to first column method
  if #whereConditions == 0 then
    local firstColumn
    for _, columnName in ipairs(columnsOrder) do
      if object[columnName] ~= nil and object[columnName] ~= "" then
        firstColumn = columnName
        break
      end
    end
    if firstColumn then
      table.insert(whereConditions, firstColumn .. " = ?")
      table.insert(whereValues, object[firstColumn])
    end
  end
  
  local whereClause = table.concat(whereConditions, " AND ")
  
  -- Skip existence check if no WHERE clause can be built
  if #whereConditions == 0 then
    -- Just insert directly
    local placeholders = string.rep("?, ", #values - 1) .. "?"
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), placeholders)
    return DatabaseManager:prepareAndExecute(insertQuery, table.unpack(values))
  end
  
  local selectQuery = string.format("SELECT COUNT(*) FROM %s WHERE %s", tableName, whereClause)
  Utils.nkprint(selectQuery, "debug")
  
  local count = 0
  local stmt = DatabaseManager.db:prepare(selectQuery)
  if not stmt then
    error("Failed to prepare statement: " .. selectQuery)
  end
  
  for i, value in ipairs(whereValues) do
    stmt:bind(i, value)
  end
  for row in stmt:nrows() do
    count = tonumber(row["COUNT(*)"])
  end
  stmt:finalize()
  
  if count > 0 and canupdate then
      -- Build UPDATE query with placeholders for prepared statement
      local updatePlaceholders = {}
      for _, column in ipairs(columns) do
        table.insert(updatePlaceholders, column .. " = ?")
      end
      local updateQuery = string.format("UPDATE %s SET %s WHERE %s", tableName, table.concat(updatePlaceholders, ", "), whereClause)
      
      -- Combine update values and where values for binding
      local allValues = {}
      for _, value in ipairs(values) do
        table.insert(allValues, value)
      end
      for _, value in ipairs(whereValues) do
        table.insert(allValues, value)
      end
      
      return DatabaseManager:prepareAndExecute(updateQuery, table.unpack(allValues))
  else
    local placeholders = string.rep("?, ", #values - 1) .. "?" -- Generate placeholders like ?, ?, ?, ...
    local insertQuery = string.format("INSERT INTO %s (%s) VALUES (%s)", tableName, table.concat(columns, ", "), placeholders)
    
    -- Execute the query using prepareAndExecute with the values array
    return DatabaseManager:prepareAndExecute(insertQuery, table.unpack(values))
  end
end


function DatabaseManager:getEntry(class, columnName, columnValue)
  
  local tableName = class.tableName
  print("Getting entry from table: " .. tableName .. " where " .. columnName .. " = " .. tostring(columnValue)) -- Debug print

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

      for key2, _ in pairs(existingColumns) do
          table.insert(existingColumnsFinal, key2)
      end

      for key, column in ipairs(columns) do
        local colName = column:match("^(%S+)")
        local finalKey = Utils.get_key_for_value(existingColumnsFinal, colName)
        if finalKey ~= nil then
          columnsFinal[finalKey] = colName
        end
      end

      for key, column in ipairs(existingColumnsFinal) do

        if columnsFinal[key] == nil then
         
          local alterQuery = string.format("ALTER TABLE %s DROP COLUMN %s", tableName, column)
          
          DatabaseManager:returnQuery(alterQuery)
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
        DatabaseManager:returnQuery(alterQuery)
        if isUnique then
          local query = string.format("CREATE UNIQUE INDEX idx_unique_%s ON %s(%s)", column:match("^(%S+)%s"), tableName, column:match("^(%S+)%s"))
          DatabaseManager:returnQuery(query)

        end
        -- self.db:exec(alterQuery)
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

  for row in DatabaseManager.db:nrows(query) do
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
    result[i] = class.new();

    for key, value in pairs(row) do
      if type(value) == "string" and value:find("{") and value:find("}") then
        local parsedList = Utils.string_to_table(value)
        result[i][key] = parsedList  -- Direct assignment instead of setKey
      else
        result[i][key] = value  -- Direct assignment instead of setKey
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
  local query = string.format("PRAGMA table_info(%s)", tableName)

  for row in DatabaseManager.db:nrows(query) do
    existingColumns[row.name] = true
  end

  return existingColumns
end

function DatabaseManager:getTableColumnsName(tableName)

  local columns = {}
  for row in DatabaseManager.db:nrows("PRAGMA table_info(" .. tableName .. ")") do
    table.insert(columns, row.name)
  end
  return columns
end


function DatabaseManager:openConnection()
  DatabaseManager.db = SQLITE3.open(DatabaseManager.dbname)
end

function DatabaseManager:closeConnection()
  if DatabaseManager.db then
    Utils.nkprint("Database closed", "debug")
    DatabaseManager.db:close()
    DatabaseManager.db = nil
  end
end

--return multiples values that can be anything
---@param callback function
---@return any ...
function DatabaseManager:withConnection(callback)
    DatabaseManager:openConnection()
    local results = {pcall(callback)}
    DatabaseManager:closeConnection()
    
    local ok = table.remove(results, 1) 
    
    if not ok then
        error(results[1])  
    end
    
    return table.unpack(results) 
end

DatabaseManager.init()
