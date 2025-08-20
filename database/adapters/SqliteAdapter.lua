-- SQLite Database Adapter
local sqlite3 = require("lsqlite3")
local new = require("objects.New")
local DatabaseAdapter = require("database.adapters.DatabaseAdapter")

---@class SqliteAdapter : DatabaseAdapter
local SqliteAdapter = {}

function SqliteAdapter.new(connectionConfig)
    local self = {}
    self.dbPath = connectionConfig.database_file
    self.db = nil
    return new._object(SqliteAdapter, self)
end

function SqliteAdapter:connect()
    if not self.db then
        self.db = sqlite3.open(self.dbPath)
    end
end

function SqliteAdapter:disconnect()
    if self.db then
        self.db:close()
        self.db = nil
    end
end

function SqliteAdapter:exec(query)
    return self.db:exec(query)
end

function SqliteAdapter:prepare(query)
    return self.db:prepare(query)
end

function SqliteAdapter:nrows(query)
    return self.db:nrows(query)
end

function SqliteAdapter:changes()
    return self.db:changes()
end

function SqliteAdapter:isConnected()
    return self.db ~= nil
end

return SqliteAdapter