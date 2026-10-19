SQLITE3_DRIVER = {
    name = "sqlite3",
    types = {
        STRING = "VARCHAR",
        TEXT = "TEXT",
        BOOLEAN = "INTEGER",
        INTEGER = "INTEGER",
        BIGINT = "INTEGER",
        DECIMAL = "DECIMAL",
        DATE = "DATE",
        DATETIME = "DATETIME",
        BINARY = "BLOB",
        JSON = "JSONB",
        UUID = "TEXT"
    },
    syntax = {
        quote = function(name) return '"' .. name .. '"' end,
        primary_key = "PRIMARY KEY",
        auto_increment = "AUTOINCREMENT",
        now = "CURRENT_TIMESTAMP",
        get_table_check_sql = function(tablename)
            return string.format("SELECT name FROM sqlite_master WHERE type='table' AND name='%s'", tablename)
        end,
        disable_fk_sql = "PRAGMA foreign_keys = OFF;",
        enable_fk_sql = "PRAGMA foreign_keys = ON;",
        get_table_columns_sql = function(tablename)
            return "PRAGMA table_info(" .. tablename .. ")"
        end,
        get_upsert_sql = function(db, tablename, columns, values, pks, updates)
            local q_table = db.dialect.syntax.quote(tablename)
            local conflict_target = {}
            for _, pk in ipairs(pks) do
                table.insert(conflict_target, db.dialect.syntax.quote(pk))
            end
            return string.format(
                "INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s",
                q_table,
                table.concat(columns, ", "),
                table.concat(values, ", "),
                table.concat(conflict_target, ", "),
                table.concat(updates, ", ")
            )
        end,
        get_last_insert_id = function(db)
            if db.conn and db.conn.getlastautoid then
                return db.conn:getlastautoid()
            end
            local cur = db:execute("SELECT last_insert_rowid()")
            if cur then
                local row = cur:fetch({}, "a")
                cur:close()
                return tonumber(row["last_insert_rowid()"] or row[1]) or 0
            end
            return 0
        end
    }
}