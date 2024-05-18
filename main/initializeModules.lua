local utils = require("utils.misc")

local init = {}



-- DO NOT USE NKPRINT DEBUG HERE !! OR IT WILL BREAK BECAUSE CONFIG ISNT GENERATED YET
function init.initialize()
    -- Function to check if LuaRocks is installed
    local function isLuaRocksInstalled()
        local status = os.execute("luarocks --version > /dev/null 2>&1")
        return status
    end
    local function isModuleInstalled(moduleName)
        local success, module = pcall(require, moduleName)
        return success
    end

    local function installModules()
        utils.nkprint("Checking Nickel modules", "info")

        local cmd = "luarocks --lua-version 5.3 --tree " .. utils.script_path() .. " install lsqlite3 && luarocks --lua-version 5.3 --tree " .. utils.script_path() .. " install toml && luarocks --lua-version 5.3 --tree " .. utils.script_path() .. " install luasec"
        os.execute(cmd)
        utils.nkprint("If there is problem run this command manually while the server is offline (You cant if you are on an hosting solution) : " .. cmd, "warn")
    end



    -- Check if LuaRocks is installed
    local installCmd = "sudo apt install -y libssl-dev cmake libsqlite3-dev build-essential libreadline-dev unzip lua5.3 && curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.10.0.tar.gz && tar -zxf luarocks-3.10.0.tar.gz && (cd luarocks-3.10.0 && ./configure) && (cd luarocks-3.10.0 && make) && (cd luarocks-3.10.0 && sudo make install) && curl -R -O https://www.sqlite.org/2024/sqlite-autoconf-3450300.tar.gz && tar -zxf sqlite-autoconf-3450300.tar.gz && (cd sqlite-autoconf-3450300 && ./configure) && (cd sqlite-autoconf-3450300 && make) && (cd sqlite-autoconf-3450300 && sudo make install)"

    if not isLuaRocksInstalled() then
        os.execute(installCmd)
        utils.nkprint("If there is problem run this command manually while the server is offline (You cant if you are on an hosting solution) : " .. installCmd, "warn")
    end

    if not isModuleInstalled("lsqlite3") or not isModuleInstalled("ssl.https") or not isModuleInstalled("toml") then
        installModules()
        utils.nkprint("If it didn't work, you may need to uninstall LuaRocks yourself and try again if you already have it installed (sudo apt remove luarocks)", "warn")
    end
end

return init