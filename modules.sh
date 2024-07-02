#!/bin/bash


script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Function to check if the script is run as root
function checkRoot() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use sudo."
        exit 1
    fi
}

askToInstall() {
    read -p "The program need you to install : LuaRocks 3.10.0 and dependencies, liblua5.3-dev, libssl-dev, sqlite3 3.45, libsqlite3, build-essential, libreadline-dev, unzip, lua5.3 | Do you want to install ? (y/n): " choice
    case "$choice" in
        y|Y ) 
            return 0  # True
            ;;
        n|N ) 
            return 1  # False
            ;;
        * ) 
            askToInstall "$1"  # Repeat the function call
            ;;
    esac
}

# Command to install LuaRocks and its dependencies
installCmd="apt update && \
            apt install -y liblua5.3-dev libssl-dev cmake libsqlite3-dev build-essential libreadline-dev unzip lua5.3 && \
            curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.10.0.tar.gz && \
            tar -zxf luarocks-3.10.0.tar.gz && \
            (cd luarocks-3.10.0 && ./configure) && \
            (cd luarocks-3.10.0 && make) && \
            (cd luarocks-3.10.0 && make install) && \
            curl -R -O https://www.sqlite.org/2024/sqlite-autoconf-3450300.tar.gz && \
            tar -zxf sqlite-autoconf-3450300.tar.gz && \
            (cd sqlite-autoconf-3450300 && ./configure) && \
            (cd sqlite-autoconf-3450300 && make) && \
            (cd sqlite-autoconf-3450300 && make install)"

# Function to install required Lua modules
function installModules() {
    luarocks --lua-version 5.3 --tree $script_dir install lsqlite3
    luarocks --lua-version 5.3 --tree $script_dir install toml 
    luarocks --lua-version 5.3 --tree $script_dir install luasec 
}

# Check for root privileges
checkRoot


if ! askToInstall; then
    echo "Install cancelled !"
    exit
fi

# Warn user about manual uninstallation if necessary
echo "If there is a problem, you may need to uninstall LuaRocks manually (sudo apt remove luarocks)."

echo "Installing LuaRocks and dependencies..."
eval $installCmd

echo "Installing Lua modules..."
installModules

echo "Installation complete."
