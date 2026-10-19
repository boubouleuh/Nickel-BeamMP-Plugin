MYSQL_DRIVER = {
    name = "mysql",
    types = {
        STRING = "VARCHAR",
        TEXT = "LONGTEXT",
        BOOLEAN = "BOOLEAN",
        INTEGER = "INT",
        BIGINT = "BIGINT",
        DECIMAL = "DECIMAL",
        DATE = "DATE",
        DATETIME = "DATETIME",
        BINARY = "BLOB",
        JSON = "JSON",
        UUID = "VARCHAR"
    },
    syntax = {
        quote = function(name) return "`" .. name .. "`" end,
        primary_key = "PRIMARY KEY",
        auto_increment = "AUTO_INCREMENT",
        now = "NOW()",
        get_table_check_sql = function(tablename)
            return string.format("SHOW TABLES LIKE '%s'", tablename)
        end,
        disable_fk_sql = "SET FOREIGN_KEY_CHECKS = 0;",
        enable_fk_sql = "SET FOREIGN_KEY_CHECKS = 1;",
        get_table_columns_sql = function(tablename)
            return "DESCRIBE `" .. tablename .. "`"
        end,
        get_upsert_sql = function(db, tablename, columns, values, pks, updates)
            local q_table = db.dialect.syntax.quote(tablename)
            return string.format(
                "INSERT INTO %s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s",
                q_table,
                table.concat(columns, ", "),
                table.concat(values, ", "),
                table.concat(updates, ", ")
            )
        end,
        get_last_insert_id = function(db)
            if db.conn and db.conn.insert_id then
                return db.conn:insert_id()
            end
            return 0
        end
    }
}