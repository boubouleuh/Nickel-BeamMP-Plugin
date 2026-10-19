DB = {}
DB.__index = DB

local function escape_value(value, dialect)
    if value == nil then return "NULL" end
    if type(value) == "boolean" then
        if dialect and dialect.name == "postgres" then return value and "TRUE" or "FALSE" end
        return value and "1" or "0"
    end
    if type(value) == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            error("Invalid numeric SQL parameter")
        end
        return tostring(value)
    end

    local text = tostring(value)
    if text:find("\0", 1, true) then
        local hex = text:gsub(".", function(char)
            return string.format("%02x", char:byte())
        end)
        if dialect and dialect.name == "postgres" then
            return "decode('" .. hex .. "', 'hex')"
        end
        return "X'" .. hex .. "'"
    end
    return "'" .. text:gsub("'", "''") .. "'"
end

local function interpolate(sql, params, dialect)
    local index = 0
    local result = sql:gsub("?", function()
        index = index + 1
        return escape_value(params[index], dialect)
    end)
    local count = params.n or #params
    if index ~= count then
        error(string.format("Expected %d SQL parameters, received %d", index, count))
    end
    return result
end


function DB.new(config)
    local self = setmetatable({
        models = {},
        config = config,
        conn = nil,
        dialect = nil,
        env = nil
    }, DB)
    
    local status, dialect = pcall(require, "NICKEL_ORM.db.drivers." .. config.engine)
    if not status then error("Dialect not found: " .. config.engine) end
    self.dialect = dialect
    
    return self
end

function DB:_run(sql, params, fetch)
    params = params or {}

    if self.conn.prepare then
        local statement = self.conn:prepare(sql)
        if not statement then error("Unable to prepare SQL statement: " .. sql) end
        if statement.bind_values then
            statement:bind_values(table.unpack(params, 1, params.n or #params))
        elseif statement.bind then
            for index = 1, params.n or #params do statement:bind(index, params[index]) end
        end
        local result = fetch and statement:nrows() or statement:step()
        if not result then
            if statement.finalize then statement:finalize() end
            error("SQL execution failed: " .. sql)
        end
        if fetch then
            local iterator = result
            return {
                fetch = function(_, _, mode)
                    return iterator()
                end,
                close = function() end
            }, statement
        end
        if statement.finalize then statement:finalize() end
        return result
    end

    local res, err = self.conn:execute(interpolate(sql, params, self.dialect))
    if not res then
        error("SQL Error: " .. tostring(err) .. " | Query: " .. sql)
    end
    return res
end

function DB:execute(sql, params)
    return self:_run(sql, params, false)
end

function DB:query(sql, params)
    if self.conn.prepare then return self:_run(sql, params, true) end
    return self:_run(sql, params, false)
end

function DB:connect()
    local engine = self.config.engine
    local luasql = require("luasql." .. engine)
    self.env = luasql[engine]()
    
    if engine == "sqlite3" then
        self.conn = self.env:connect(self.config.database)
    else
        self.conn = self.env:connect(
            self.config.database, 
            self.config.user, 
            self.config.pass, 
            self.config.host, 
            self.config.port
        )
    end

    if self.dialect.syntax.enable_fk_sql then
        self:execute(self.dialect.syntax.enable_fk_sql)
    end

    return self.conn ~= nil
end