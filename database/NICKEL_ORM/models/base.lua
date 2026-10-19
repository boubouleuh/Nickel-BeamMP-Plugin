-- Represents a query builder for building and executing SQL queries.
---@class QueryBuilder
---@field where fun(self: QueryBuilder, col: string, op: string, val: any): QueryBuilder
---@field limit fun(self: QueryBuilder, n: number): QueryBuilder
---@field offset fun(self: QueryBuilder, n: number): QueryBuilder
---@field order fun(self: QueryBuilder, col: string, direction?: string): QueryBuilder
---@field count fun(self: QueryBuilder): number
---@field get fun(self: QueryBuilder): ModelInstance[]

---
-- Represents a single row/instance of a model.
---@class ModelInstance
---@field __tablename__ string
---@field save fun(self: ModelInstance): boolean, string?
---@field delete fun(self: ModelInstance): boolean, string?

---
-- Represents a model class (table definition and query interface).
---@class ModelClass
---@field __tablename__ string
---@field new fun(self: ModelClass, data?: table): ModelInstance
---@field find fun(self: ModelClass, cond: table): ModelInstance[]
---@field where fun(self: ModelClass, col: string, op: string, val: any): QueryBuilder
---@field limit fun(self: ModelClass, n: number): QueryBuilder
---@field offset fun(self: ModelClass, n: number): QueryBuilder
---@field order fun(self: ModelClass, col: string, direction?: string): QueryBuilder
---@field all fun(self: ModelClass): ModelInstance[]
---@field count fun(self: ModelClass): number
---@class ModelFactory
---@overload fun(def: {__tablename__: string, [number]: Field}): ModelClass
---@field __last_db any
---@field _registry table<string, ModelClass>
Model = {}

Model.__last_db = nil
Model._registry = {}

local InstanceMethods = {}

local function add_param(params, value)
    params.n = (params.n or #params) + 1
    params[params.n] = value
end

local function quote_column(db, column)
    if type(column) ~= "string" or not column:match("^[%a_][%w_]*$") then
        error("Invalid SQL column name")
    end
    return db.dialect.syntax.quote(column)
end

local function format_default(db, value)
    if type(value) == "string" then return "'" .. value:gsub("'", "''") .. "'" end
    if type(value) == "boolean" then
        if db.dialect.name == "postgres" then return value and "TRUE" or "FALSE" end
        return value and "1" or "0"
    end
    return tostring(value)
end

--- Handles dynamic relationship loading and instance methods.
---@param key string
---@return any
function InstanceMethods:__index(key)
    local method = rawget(InstanceMethods, key)
    if method then return method end

    local tablename = rawget(self, "__tablename")
    local class = Model._registry[tablename]
    if not class then return nil end

    local targetModel = Model._registry[key]
    if targetModel then
        local targetTablename = targetModel.__tablename__
        
        -- Relation: Inverse lookup
        local relFromTarget = targetModel._relations[tablename]
        if relFromTarget then
            return targetModel:where(relFromTarget.self_col, "=", self[relFromTarget.target_col]):get()
        end
        
        -- Relation: Direct lookup
        local relFromSelf = class._relations[targetTablename]
        if relFromSelf then
            return targetModel:where(relFromSelf.target_col, "=", self[relFromSelf.self_col]):get()
        end
    end

    return nil
end

local function sync_table(tablename, fields)
    local db = Model.__last_db
    if not db or not db.dialect then return end
    local q_table = db.dialect.syntax.quote(tablename)
    
    local function get_sql_type(field)
        local base = db.dialect.types[field.type or field._type] or (field.type or field._type)
        if field.decimal_precision then
            return string.format("%s(%d,%d)", base, field.decimal_precision.total, field.decimal_precision.decimals)
        elseif field.max_length and not (db.dialect.name == "postgres" and field.type == "UUID") then
            return string.format("%s(%d)", base, field.max_length)
        end
        return base
    end
    
    -- Vérification propre selon le dialecte
    local check_sql = db.dialect.syntax.get_table_check_sql(tablename)
    local res = db:execute(check_sql)
    local exists = res and res:fetch({}, "a") or nil
    res:close()
    
    local table_exists = false
    if exists then
        -- Pour PostgreSQL / SQLite / MySQL, on regarde les clés de la table
        local val = exists.exists or exists.EXISTS or exists[next(exists)] or next(exists)
        table_exists = (val ~= nil and val ~= false and val ~= "f" and val ~= 0)
    end
    
    if not table_exists then
        local cols, pks, fks = {}, {}, {}
        local names = {}
        for n in pairs(fields) do table.insert(names, n) end
        table.sort(names)
        local pk_inline = false
        
        for _, name in ipairs(names) do
            local field = fields[name]
            local line = db.dialect.syntax.quote(name) .. " " .. get_sql_type(field)

            if field.auto_increment then
                if db.dialect.name == "sqlite3" then
                    line = line .. " PRIMARY KEY AUTOINCREMENT"
                    pk_inline = true
                elseif db.dialect.name == "postgres" then
                    line = db.dialect.syntax.quote(name) .. " SERIAL"
                else
                    line = line .. " " .. db.dialect.syntax.auto_increment
                end
            end
            if field.not_null then line = line .. " NOT NULL" end
            if field.unique then line = line .. " UNIQUE" end
            if field.default ~= nil then
                line = line .. " DEFAULT " .. format_default(db, field.default)
            end
            if field.primary_key and not (field.auto_increment and db.dialect.name == "sqlite3") then
                table.insert(pks, db.dialect.syntax.quote(name))
            end
            if field.foreign_key then
                table.insert(fks, string.format("CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s(%s) ON DELETE %s ON UPDATE %s",
                    db.dialect.syntax.quote("fk_" .. tablename .. "_" .. name),
                    db.dialect.syntax.quote(name),
                    db.dialect.syntax.quote(field.foreign_key.table),
                    db.dialect.syntax.quote(field.foreign_key.column),
                    field.foreign_key.on_delete,
                    field.foreign_key.on_update))
            end
            table.insert(cols, line)
        end
        
        if #pks > 0 and not pk_inline then
            table.insert(cols, "PRIMARY KEY (" .. table.concat(pks, ", ") .. ")")
        end
        
        for _, fk in ipairs(fks) do table.insert(cols, fk) end
        
        local sql = ""
        if db.dialect.name == "postgres" then
            sql = string.format("CREATE TABLE %s (%s);", q_table, table.concat(cols, ", "))
        else
            sql = string.format("CREATE TABLE IF NOT EXISTS %s (%s);", q_table, table.concat(cols, ", "))
        end
        
        db:execute(sql)
        print("[ORM] Created table: " .. tablename)
    else
        local current_cols = {}
        if db.dialect.name == "sqlite3" then
            local col_res = db:execute(db.dialect.syntax.get_table_columns_sql(tablename))
            local row = col_res:fetch({}, "a")
            while row and next(row) ~= nil do
                current_cols[row.name] = true
                row = col_res:fetch({}, "a")
            end
            col_res:close()
        else
            local col_sql = db.dialect.syntax.get_table_columns_sql(tablename)
            local col_res = db:execute(col_sql)
            local row = col_res:fetch({}, "a")
            while row do
                current_cols[row.Field or row.field or row.column_name] = true
                row = col_res:fetch({}, "a")
            end
            col_res:close()
        end
        
        for name, field in pairs(fields) do
            if not current_cols[name] then
                local sql = string.format("ALTER TABLE %s ADD COLUMN %s %s",
                    q_table, db.dialect.syntax.quote(name), get_sql_type(field))
                if field.not_null then sql = sql .. " NOT NULL" end
                if field.default ~= nil then
                    sql = sql .. " DEFAULT " .. format_default(db, field.default)
                end
                db:execute(sql)
                print("[ORM] Added missing column '" .. name .. "' to table '" .. tablename .. "'")
            end
        end
    end
end

--- Saves the current instance to the database using an UPSERT logic.
---@return boolean success
---@return string? error_message
function InstanceMethods:save()
    local tablename = rawget(self, "__tablename")
    local class = Model._registry[tablename]
    local db = Model.__last_db
    if not db then error("No database connection established") end
    local columns, values, updates, field_names, update_names = {}, {}, {}, {}, {}
    
    for name, field in pairs(class._fields) do
        if field.auto_increment and self[name] == nil then
            -- Skip auto-increment fields if not set, they will be filled by the database
        else
            if field.not_null and not field.auto_increment and self[name] == nil then
                error("Constraint Violation: Field '" .. name .. "' cannot be null")
            end
            
            table.insert(columns, db.dialect.syntax.quote(name))
            table.insert(values, "?")
            table.insert(field_names, name)
            if not field.primary_key then
                table.insert(updates, string.format("%s = ?", db.dialect.syntax.quote(name)))
                table.insert(update_names, name)
            end
        end
    end

    local has_pks_filled = true
    for _, pk in ipairs(class._pks) do if self[pk] == nil then has_pks_filled = false end end

    local sql = ""
    if has_pks_filled and #updates > 0 then
        if db.dialect.syntax.get_upsert_sql then
            sql = db.dialect.syntax.get_upsert_sql(db, class.__tablename__, columns, values, class._pks, updates)
        else
            sql = string.format(
                "INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s",
                db.dialect.syntax.quote(class.__tablename__),
                table.concat(columns, ", "),
                table.concat(values, ", "),
                table.concat(updates, ", ")
            )
        end
    else
        sql = string.format(
            "INSERT INTO %s (%s) VALUES (%s)",
            db.dialect.syntax.quote(class.__tablename__),
            table.concat(columns, ", "),
            table.concat(values, ", ")
        )
    end

    local params = { n = 0 }
    for _, name in ipairs(field_names) do
        add_param(params, self[name])
    end
    if #updates > 0 and has_pks_filled then
        for _, name in ipairs(update_names) do add_param(params, self[name]) end
    end

    db:execute("SAVEPOINT nickel_orm_save")
    local executed, result = pcall(db.execute, db, sql, params)
    if not executed then
        pcall(db.execute, db, "ROLLBACK TO SAVEPOINT nickel_orm_save")
        pcall(db.execute, db, "RELEASE SAVEPOINT nickel_orm_save")
        return false, result
    end
    if result == nil or result == false then return false, "SQL execution failed" end
    db:execute("RELEASE SAVEPOINT nickel_orm_save")

    local last_id = 0
    if not has_pks_filled and db.dialect.syntax.get_last_insert_id then
        last_id = db.dialect.syntax.get_last_insert_id(db) or 0
    end
    if last_id and last_id > 0 then
        for name, field in pairs(class._fields) do
            if field.auto_increment then self[name] = last_id end
        end
    end
    return true
end

--- Delete this instance from the database.
---@return boolean success
---@return string? error_message
function InstanceMethods:delete()
    local tablename = rawget(self, "__tablename")
    local class = Model._registry[tablename]
    local db = Model.__last_db
    if not db then return false, "No database connection established" end
    if #class._pks == 0 then return false, "No primary key defined for this model" end

    local where_clauses, params = {}, { n = 0 }
    for _, pk in ipairs(class._pks) do
        table.insert(where_clauses, string.format("%s = ?", db.dialect.syntax.quote(pk)))
        add_param(params, self[pk])
    end
    local sql = string.format("DELETE FROM %s WHERE %s", db.dialect.syntax.quote(class.__tablename__), table.concat(where_clauses, " AND "))
    local res, err = pcall(db.execute, db, sql, params)
    if not res then return false, err end
    return true
end

---@class QueryBuilder
local QueryBuilder = {}
QueryBuilder.__index = QueryBuilder

--- Creates a new QueryBuilder instance.
---@param class ModelClass
---@return QueryBuilder
function QueryBuilder:new(class)
    return setmetatable({
        class = class,
        _where = {},
        _params = { n = 0 },
        _limit = nil
    }, self)
end

--- Adds an ORDER BY clause to the query.
---@param col string Column name to order by
---@param direction string "ASC" or "DESC"
---@return QueryBuilder
function QueryBuilder:order(col, direction)
    local db = Model.__last_db
    local dir = string.upper(direction or "ASC")
    if dir ~= "ASC" and dir ~= "DESC" then error("Invalid order direction") end
    self._order = string.format("%s %s", quote_column(db, col), dir)
    return self
end

--- Executes a COUNT query based on the current filters.
---@return number
function QueryBuilder:count()
    local db = Model.__last_db
    if not db then return 0 end
    
    local sql = string.format("SELECT COUNT(*) as count FROM %s", db.dialect.syntax.quote(self.class.__tablename__))
    
    if #self._where > 0 then
        sql = sql .. " WHERE " .. table.concat(self._where, " AND ")
    end
    
    local cur, statement = db:query(sql, self._params)
    if not cur then
        print("[SQL ERROR] Count query failed: " .. tostring(err))
        return 0
    end

    local row = cur:fetch({}, "a")
    local count = tonumber(row and row.count) or 0
    if cur.close then cur:close() end
    if statement and statement.finalize then statement:finalize() end
    return count
end

--- Sets an offset for the query results.
---@param n number
---@return QueryBuilder
function QueryBuilder:offset(n)
    if type(n) ~= "number" or n < 0 or n ~= math.floor(n) then error("Invalid query offset") end
    self._offset = n
    return self
end

--- Adds a WHERE condition to the query.
---@param col string Column name
---@param op string SQL operator (=, >, LIKE, etc.)
---@param val any Value to compare
---@return QueryBuilder
function QueryBuilder:where(col, op, val)
    local db = Model.__last_db
    if not db then return self end
    local allowed_operators = { ["="] = true, ["<>"] = true, ["!="] = true, [">"] = true, [">="] = true, ["<"] = true, ["<="] = true, ["LIKE"] = true, ["IS"] = true }
    op = string.upper(op)
    if not allowed_operators[op] then error("Invalid SQL operator") end
    if val == nil and op == "=" then op = "IS" end
    if val == nil and (op == "!=" or op == "<>") then op = "IS NOT" end
    local condition = val == nil and string.format("%s %s NULL", quote_column(db, col), op)
        or string.format("%s %s ?", quote_column(db, col), op)
    table.insert(self._where, condition)
    if val ~= nil then add_param(self._params, val) end
    return self
end

--- Sets a limit for the number of records returned.
---@param n number
---@return QueryBuilder
function QueryBuilder:limit(n)
    if type(n) ~= "number" or n < 0 or n ~= math.floor(n) then error("Invalid query limit") end
    self._limit = n
    return self
end

--- Executes the SELECT query and returns model instances.
---@return ModelInstance[]
function QueryBuilder:get()
    local db = Model.__last_db
    if not db then return {} end
    local sql = string.format("SELECT * FROM %s", db.dialect.syntax.quote(self.class.__tablename__))
    
    if #self._where > 0 then
        sql = sql .. " WHERE " .. table.concat(self._where, " AND ")
    end
    if self._order then
        sql = sql .. " ORDER BY " .. self._order
    end
    if self._limit then 
        sql = sql .. " LIMIT " .. self._limit 
        if self._offset then sql = sql .. " OFFSET " .. self._offset end
    end
        
    local cur, statement = db:query(sql, self._params)
    if not cur then
        print("[SQL ERROR] Query failed")
        return {}
    end

    local instances = {}
    local row = cur:fetch({}, "a") 
    while row and next(row) ~= nil do
        local data = {}
        for k, v in pairs(row) do
            local fieldDef = self.class._fields[k]
            if fieldDef and v ~= nil then
                local fType = fieldDef.type or fieldDef._type
                if fType == "INTEGER" then
                    data[k] = tonumber(v)
                elseif fType == "BOOLEAN" then
                    data[k] = (v == "1" or v == 1 or v == "true" or v == "t" or v == true)
                else
                    data[k] = v
                end
            else
                data[k] = v
            end
        end
        
        table.insert(instances, self.class:new(data))
        row = cur:fetch({}, "a")
    end
    
    if cur.close then cur:close() end
    if statement and statement.finalize then statement:finalize() end
    return instances
end

--- Internal function to define a new Model.
---@param def {__tablename__: string, [number]: Field}
---@return ModelClass | any
local function __CreateModel__(def)
    ---@class NewClass : ModelClass
    local NewClass = {
        __tablename__ = def.__tablename__,
        _fields = {},
        _pks = {},
        _relations = {}
    }

    for _, v in ipairs(def) do
        if type(v) == "table" and (v.name or v._name) then
            local name = v.name or v._name
            NewClass._fields[name] = v
            if v.primary_key then table.insert(NewClass._pks, name) end
            if v.foreign_key then
                NewClass._relations[v.foreign_key.table] = {
                    self_col = name,
                    target_col = v.foreign_key.column
                }
            end
        end
    end

    Model._registry[def.__tablename__] = NewClass

    if Model.__last_db then
        sync_table(NewClass.__tablename__, NewClass._fields)
    end

    function NewClass:new(data)
        local inst = {}
        data = data or {}
        for fname, field in pairs(NewClass._fields) do
            if data[fname] ~= nil then
                inst[fname] = data[fname]
            elseif field.default ~= nil then
                inst[fname] = field.default
            end
        end
        for k, v in pairs(data) do
            if inst[k] == nil then inst[k] = v end
        end
        inst.__tablename = NewClass.__tablename__
        setmetatable(inst, {
            __index = function(t, key)
                local v = rawget(t, key)
                if v ~= nil then return v end
                local cv = NewClass[key]
                if cv ~= nil then return cv end
                local mv = InstanceMethods[key]
                if mv ~= nil and type(mv) == "function" then return mv end
                return InstanceMethods.__index(t, key)
            end
        })
        return inst
    end

    function NewClass:limit(n) return QueryBuilder:new(NewClass):limit(n) end
    function NewClass:offset(n) return QueryBuilder:new(NewClass):offset(n) end
    function NewClass:order(col, dir) return QueryBuilder:new(NewClass):order(col, dir) end
    function NewClass:all() return QueryBuilder:new(NewClass):get() end

    function NewClass:count()
        local db = Model.__last_db
        if not db then return 0 end
        local sql = string.format("SELECT COUNT(*) as count FROM %s", db.dialect.syntax.quote(self.__tablename__))
        local cur, err = db:execute(sql)
        if not cur then
            print("[SQL ERROR] Count query failed: " .. tostring(err))
            return 0
        end
        local row = cur:fetch({}, "a")
        local count = tonumber(row and row.count) or 0
        cur:close()
        return count
    end

    function NewClass:find(cond)
        local qb = QueryBuilder:new(NewClass)
        for k, v in pairs(cond) do qb:where(k, "=", v) end
        return qb:get()
    end

    function NewClass:where(col, op, val)
        return QueryBuilder:new(NewClass):where(col, op, val)
    end

    return setmetatable(NewClass, {
        __call = function(t, data) return t:new(data) end
    })
end

function Model:sync()
    print("[ORM] Starting auto-migration...")
    for tablename, class in pairs(Model._registry) do
        sync_table(tablename, class._fields)
    end
    print("[ORM] All tables are up to date.")
end

setmetatable(Model, {
    __call = function(_, def)
        return __CreateModel__(def)
    end
})