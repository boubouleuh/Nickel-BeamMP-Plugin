# Database Configuration Guide

## Overview
Nickel now supports multiple database types: SQLite (default) and MySQL. You can easily switch between them by modifying the configuration file.

## Configuration Options

### SQLite (Default)
```toml
[sync]
database_type = "sqlite"
database_file = "database/nickel.sqlite"
```

### MySQL
```toml
[sync]
database_type = "mysql"
mysql_host = "localhost"
mysql_port = 3306
mysql_database = "nickel_beammp"
mysql_username = "your_username"
mysql_password = "your_password"
database_file = ""  # Not used for MySQL
```

## Requirements

### SQLite
- No additional requirements (included by default)

### MySQL
- Requires `luasql-mysql` library to be installed
- MySQL server must be running and accessible
- Database must exist (create manually or via script)

## Migration Guide

### From SQLite to MySQL
1. Install `luasql-mysql` library
2. Create MySQL database and user
3. Update `NickelConfig.toml` with MySQL settings
4. Restart the server

### From MySQL to SQLite
1. Update `NickelConfig.toml` with SQLite settings
2. Restart the server

## Notes
- The database interface remains the same regardless of type
- Existing code doesn't need to be modified
- Configuration validation prevents invalid setups
- Automatic fallback to SQLite if MySQL is unavailable

## Adding New Database Types
The architecture supports adding new database types by:
1. Creating a new adapter in `database/adapters/`
2. Implementing the `DatabaseAdapter` interface
3. Adding support in `DatabaseFactory.lua`
4. Adding configuration options to `Settings.lua`