-- Try to load libraries, with a fallback to arm64 architecture if the primary fails.

-- TOML
TOML = Tree.LoadLib("lua/5.3/toml")
if not TOML then
    TOML = Tree.LoadLib("lua/5.3/arm64/toml")
end
if not TOML then
    error("FATAL: Could not load TOML library for any architecture.")
end

-- LSQLITE3
SQLITE3 = Tree.LoadLib("lua/5.3/lsqlite3")
if not SQLITE3 then
    SQLITE3 = Tree.LoadLib("lua/5.3/arm64/lsqlite3")
end
if not SQLITE3 then
    error("FATAL: Could not load LSQLITE3 library for any architecture.")
end

-- MIME
MIME = Tree.LoadLib("lua/5.3/mime/core", "luaopen_mime_core")
if not MIME then
    MIME = Tree.LoadLib("lua/5.3/arm64/mime/core", "luaopen_mime_core")
end
if not MIME then
    error("FATAL: Could not load MIME library for any architecture.")
end

-- LUASQL-MYSQL
MYSQL = Tree.LoadLib("lua/5.3/mysql", "luaopen_luasql_mysql")
if not MYSQL then
    MYSQL = Tree.LoadLib("lua/5.3/arm64/mysql", "luaopen_luasql_mysql")
end
if not MYSQL then
    error("FATAL: Could not load LUASQL-MYSQL library for any architecture.")
end
