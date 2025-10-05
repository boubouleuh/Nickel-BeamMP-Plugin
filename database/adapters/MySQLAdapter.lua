
MySQLAdapter = {}

function MySQLAdapter.new(connectionConfig)
    local self = {}
    self.host = connectionConfig.mysql_host or "localhost"
    self.port = connectionConfig.mysql_port or 3306
    self.database = connectionConfig.mysql_database or "nickel"
    self.username = connectionConfig.mysql_username or ""
    self.password = connectionConfig.mysql_password or ""
    self.connection = nil
    self.env = nil -- LuaSQL environment
    self.changesCount = 0
    self.hasLoggedConnection = false
    self.luasql = MYSQL

    local env, envErr = self.luasql.mysql()
    if env then
        self.env = env
        self.libraryAvailable = true
        Utils.nkprint("MySQL library loaded (client " .. tostring(self.luasql._CLIENTVERSION or '?') .. ")", "info")
    else
        Utils.nkprint("MySQL env creation failed: " .. tostring(envErr), "error")
    end



    return New._object(MySQLAdapter, self)
end

function MySQLAdapter:connect()
    if not self.libraryAvailable then
        error("MySQL library not available. Please install luasql-mysql to use MySQL database.")
    end
    if not self.env then
        error("MySQL environment not initialized (luasql.mysql() failed earlier)")
    end
    if not self.connection then
        local conn, connErr = self.env:connect(self.database, self.username, self.password, self.host, self.port)
        if not conn then
            error("Failed to connect to MySQL database at " .. self.host .. ":" .. self.port .. "/" .. self.database .. " (" .. tostring(connErr) .. ")")
        end
        self.connection = conn
        if not self.hasLoggedConnection then
            Utils.nkprint("Connected to MySQL database: " .. self.host .. ":" .. self.port .. "/" .. self.database, "info")
            self.hasLoggedConnection = true
        end
    end
end

function MySQLAdapter:disconnect()
    if self.connection then
        self.connection:close()
        self.connection = nil
    end
end

function MySQLAdapter:exec(query)
    if not self.connection then
        error("Not connected to database")
    end
    if query:match("^%s*CREATE%s+TABLE") then
    end
    local cursor, error_msg = self.connection:execute(query)
    if not cursor then
        error("MySQL query failed: " .. (error_msg or "Unknown error") .. " | QUERY= " .. query)
    end

    if type(cursor) == "number" then
        self.changesCount = cursor
        if cursor > 0 then
            return 0
        else
            return "nickel.nochange"
        end
    else
        if cursor and cursor.close then
            -- SELECT: we do not want to close immediately if nrows() will iterate; here exec() used for non-SELECT only.
            cursor:close()
        end
        self.changesCount = 0
        return 0
    end
end

function MySQLAdapter:prepare(query)
    -- MySQL adapter with prepared statement simulation
    -- This is a simplified implementation
    local stmt = {
        query = query,
        adapter = self,
        bindings = {}
    }
    
    function stmt:bind(index, value)
        self.bindings[index] = value
    end
    
    function stmt:bind_values(...)
        local values = {...}
        for i, value in ipairs(values) do
            self.bindings[i] = value
        end
    end
    
    function stmt:step()
        -- Replace placeholders with bound values
        local finalQuery = self.query
        for i, value in ipairs(self.bindings) do
            local placeholder = "%?"
            if type(value) == "string" then
                value = "'" .. value:gsub("'", "''") .. "'"
            end
            finalQuery = finalQuery:gsub(placeholder, tostring(value), 1)
        end
        
        local result = self.adapter:exec(finalQuery)
        return result
    end
    
    function stmt:nrows()
        -- Execute query and return iterator
        local finalQuery = self.query
        for i, value in ipairs(self.bindings) do
            local placeholder = "%?"
            if type(value) == "string" then
                value = "'" .. value:gsub("'", "''") .. "'"
            end
            finalQuery = finalQuery:gsub(placeholder, tostring(value), 1)
        end
        
        local cursor = self.adapter.connection:execute(finalQuery)
        if not cursor then
            return function() return nil end
        end
        
        return function()
            local row = cursor:fetch({}, "a")
            if not row then
                cursor:close()
                return nil
            end
            return row
        end
    end
    
    function stmt:finalize()
        self.bindings = {}
    end
    
    return stmt
end

function MySQLAdapter:nrows(query)
    if not self.connection then
        error("Not connected to database")
    end
    
    local cursor = self.connection:execute(query)
    if not cursor then
        return function() return nil end
    end
    
    return function()
        local row = cursor:fetch({}, "a")
        if not row then
            cursor:close()
            return nil
        end
        return row
    end
end

function MySQLAdapter:changes()
    return self.changesCount or 0
end

function MySQLAdapter:isConnected()
    return self.connection ~= nil
end
