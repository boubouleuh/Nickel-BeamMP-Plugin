POSTGRES_DRIVER = {
    name = "postgres",
    types = {
        STRING = "varchar",
        TEXT = "text",
        BOOLEAN = "boolean",
        INTEGER = "integer",
        BIGINT = "bigint",
        DECIMAL = "decimal",
        DATE = "date",
        DATETIME = "timestamptz",
        BINARY = "bytea",
        JSON = "json",
        UUID = "uuid"
    },
    syntax = {
        quote = function(name) return '"' .. name .. '"' end,
        primary_key = "PRIMARY KEY",
        auto_increment = "SERIAL",
        now = "now()",
        get_table_check_sql = function(tablename)
            return string.format(
                "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '%s');",
                tablename
            )
        end,
        get_table_columns_sql = function(tablename)
            return string.format(
                "SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '%s';",
                tablename
            )
        end,
        get_upsert_sql = function(db, tablename, columns, values, pks, updates)
            local conflict_target = {}
            for _, pk in ipairs(pks) do
                table.insert(conflict_target, db.dialect.syntax.quote(pk))
            end
            return string.format(
                "INSERT INTO %s (%s) VALUES (%s) ON CONFLICT (%s) DO UPDATE SET %s",
                db.dialect.syntax.quote(tablename),
                table.concat(columns, ", "),
                table.concat(values, ", "),
                table.concat(conflict_target, ", "),
                table.concat(updates, ", ")
            )
        end,
        get_last_insert_id = function(db)
            local cursor = db:execute("SELECT LASTVAL() AS id")
            if not cursor then return 0 end
            local row = cursor:fetch({}, "a")
            if cursor.close then cursor:close() end
            return tonumber(row and (row.id or row.ID)) or 0
        end
    }
}