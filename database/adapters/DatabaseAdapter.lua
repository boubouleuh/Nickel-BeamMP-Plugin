
DatabaseAdapter = {}

-- Abstract constructor - should be overridden by implementations
function DatabaseAdapter.new(connectionConfig)
    error("DatabaseAdapter.new() must be implemented by subclasses")
end

-- Abstract methods - must be implemented by all database adapters

function DatabaseAdapter:connect()
    error("connect() method must be implemented by database adapter")
end

function DatabaseAdapter:disconnect()
    error("disconnect() method must be implemented by database adapter")
end

function DatabaseAdapter:exec(query)
    error("exec() method must be implemented by database adapter")
end

function DatabaseAdapter:prepare(query)
    error("prepare() method must be implemented by database adapter")
end

function DatabaseAdapter:nrows(query)
    error("nrows() method must be implemented by database adapter")
end

function DatabaseAdapter:changes()
    error("changes() method must be implemented by database adapter")
end

function DatabaseAdapter:isConnected()
    error("isConnected() method must be implemented by database adapter")
end