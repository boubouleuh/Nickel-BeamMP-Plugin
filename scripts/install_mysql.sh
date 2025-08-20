#!/bin/bash
# MySQL Library Installation Script for Nickel BeamMP Plugin

echo "Nickel MySQL Library Installation Script"
echo "========================================"

# Detect OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux OS"
    
    # Check if LuaRocks is installed
    if command -v luarocks >/dev/null 2>&1; then
        echo "LuaRocks found, installing luasql-mysql..."
        luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql
        
        if [ $? -eq 0 ]; then
            echo "✓ MySQL library installed successfully!"
        else
            echo "✗ Failed to install MySQL library"
            echo "You may need to install MySQL development headers first:"
            echo "  Ubuntu/Debian: sudo apt-get install libmysqlclient-dev"
            echo "  CentOS/RHEL: sudo yum install mysql-devel"
        fi
    else
        echo "LuaRocks not found. Please install LuaRocks first."
        echo "Visit: https://luarocks.org/"
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Detected Windows OS"
    echo "For Windows, please:"
    echo "1. Install MySQL client libraries"
    echo "2. Install LuaRocks"
    echo "3. Run: luarocks install luasql-mysql"
    echo ""
    echo "Or download pre-compiled binaries and place them in the lib/ directory"
    
else
    echo "Unsupported OS: $OSTYPE"
    echo "Please install luasql-mysql manually using LuaRocks:"
    echo "  luarocks install luasql-mysql"
fi

echo ""
echo "After installation, restart your BeamMP server and set database_type = \"mysql\" in NickelConfig.toml"