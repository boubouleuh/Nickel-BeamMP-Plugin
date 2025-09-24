
SqliteAdapter = {}

function SqliteAdapter.new(connectionConfig)
    local self = {}
    self.dbPath = connectionConfig.database_file
    self.db = nil
    return New._object(SqliteAdapter, self)
end

function SqliteAdapter:connect()
    if self.db then return end
    if not self.dbPath or self.dbPath == "" then
        error("SqliteAdapter: dbPath is missing")
    end
    self.db = SQLITE3.open(self.dbPath)
    if not self.db then
        error("SqliteAdapter: failed to open database at path: " .. tostring(self.dbPath))
    end
end

function SqliteAdapter:disconnect()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

function SqliteAdapter:exec(query)
    if not self.db then
        error("SqliteAdapter: exec called while database not connected")
    end
    return self.db:exec(query)
end

function SqliteAdapter:prepare(query)
    if not self.db then
        error("SqliteAdapter: prepare called while database not connected")
    end
    return self.db:prepare(query)
end

function SqliteAdapter:nrows(query)
    if not self.db then
        error("SqliteAdapter: nrows called while database not connected")
    end
    return self.db:nrows(query)
end

function SqliteAdapter:changes()
    return self.db:changes()
end

function SqliteAdapter:isConnected()
    return self.db ~= nil
end
