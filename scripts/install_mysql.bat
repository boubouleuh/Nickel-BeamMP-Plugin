@echo off
REM MySQL Library Installation Script for Nickel BeamMP Plugin (Windows)

echo Nickel MySQL Library Installation Script (Windows)
echo ==================================================

echo.
echo For Windows installation, please follow these steps:
echo.
echo 1. Install MySQL client libraries:
echo    - Download MySQL from https://dev.mysql.com/downloads/mysql/
echo    - Or install via package manager (chocolatey, scoop, etc.)
echo.
echo 2. Install LuaRocks:
echo    - Download from https://luarocks.org/
echo    - Follow installation instructions
echo.
echo 3. Install luasql-mysql:
echo    luarocks install luasql-mysql
echo.
echo 4. If compilation fails, try downloading pre-compiled binaries:
echo    - Place luasql-mysql DLL files in the lib/lua/5.3/ or lib/lua/5.4/ directory
echo.
echo 5. Configure Nickel:
echo    - Edit NickelConfig.toml
echo    - Set database_type = "mysql"
echo    - Configure MySQL connection settings
echo.
echo 6. Restart your BeamMP server
echo.

pause