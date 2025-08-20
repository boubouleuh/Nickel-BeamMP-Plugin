# Database Migration Guide

## SQLite to MySQL Migration

### Prerequisites
1. MySQL server installed and running
2. `luasql-mysql` library installed (use provided installation scripts)
3. MySQL database and user created with appropriate privileges

### Step 1: Create MySQL Database
```sql
CREATE DATABASE nickel_beammp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'nickel_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON nickel_beammp.* TO 'nickel_user'@'localhost';
FLUSH PRIVILEGES;
```

### Step 2: Export SQLite Data
You can use various tools to export SQLite data:

#### Option A: Using sqlite3 command line
```bash
sqlite3 database/db.sqlite .dump > nickel_export.sql
```

#### Option B: Using DB Browser for SQLite
1. Open your SQLite database file
2. Go to File → Export → Database to SQL file
3. Save as `nickel_export.sql`

### Step 3: Convert SQLite SQL to MySQL
SQLite and MySQL have some syntax differences. Common changes needed:

1. Remove SQLite-specific pragmas
2. Change `AUTOINCREMENT` to `AUTO_INCREMENT`
3. Update data types if needed:
   - `TEXT` → `VARCHAR(255)` or `TEXT`
   - `REAL` → `DECIMAL` or `FLOAT`

### Step 4: Import to MySQL
```bash
mysql -u nickel_user -p nickel_beammp < nickel_export.sql
```

### Step 5: Update Configuration
Edit `NickelConfig.toml`:
```toml
[sync]
database_type = "mysql"
mysql_host = "localhost"
mysql_port = 3306
mysql_database = "nickel_beammp"
mysql_username = "nickel_user"
mysql_password = "secure_password"
database_file = ""  # Not used for MySQL
```

### Step 6: Test Migration
1. Restart BeamMP server with Nickel plugin
2. Check server logs for successful MySQL connection
3. Verify that user data and permissions are working correctly

## MySQL to SQLite Migration

### Step 1: Export MySQL Data
```bash
mysqldump -u nickel_user -p nickel_beammp > nickel_mysql_export.sql
```

### Step 2: Convert MySQL SQL to SQLite
1. Remove MySQL-specific commands (`USE database_name`, etc.)
2. Change `AUTO_INCREMENT` to `AUTOINCREMENT`
3. Update data types as needed

### Step 3: Import to SQLite
```bash
sqlite3 new_database.sqlite < converted_export.sql
```

### Step 4: Update Configuration
Edit `NickelConfig.toml`:
```toml
[sync]
database_type = "sqlite"
database_file = "database/new_database.sqlite"
```

## Automatic Migration Tool (Future)
A future update may include an automatic migration tool that can:
- Export data from one database type
- Convert schema and data automatically  
- Import to the target database type
- Validate the migration

## Backup Recommendations
Always backup your database before migration:
- SQLite: Copy the `.sqlite` file
- MySQL: Use `mysqldump` to create a backup

## Troubleshooting
- **Connection issues**: Check MySQL server status and credentials
- **Schema differences**: Verify table structures match between databases
- **Data type issues**: Some data types may need manual conversion
- **Character encoding**: Ensure UTF-8 encoding is used consistently