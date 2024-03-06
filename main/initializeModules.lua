local utils = require("utils.misc")

local init = {}

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
        print("Nickel modules check")

        os.execute("luarocks --tree " .. utils.script_path() .. " install lsqlite3 && luarocks --tree " .. utils.script_path() .. " install toml && luarocks --tree " .. utils.script_path() .. " install luasec")
    end

    -- Check if LuaRocks is installed
    if not isLuaRocksInstalled() then
        print("HEY ! Nickel will install Luarocks automatically and will probably need your permissions ! In order to use Nickel you will need to type 'Y' to accept if its asking you. Otherwise, run this command yourself : \n sudo apt install build-essential libreadline-dev unzip lua5.3 && curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.10.0.tar.gz && tar -zxf luarocks-3.10.0.tar.gz && (cd luarocks-3.10.0 && ./configure) && (cd luarocks-3.10.0 && make) && (cd luarocks-3.10.0 && sudo make install) \n STOP THE SERVER BEFORE IF YOU WANT TO RUN IT MANUALLY")
        os.execute("sudo apt install sqlite3 build-essential libreadline-dev unzip lua5.3 && curl -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.10.0.tar.gz && tar -zxf luarocks-3.10.0.tar.gz && (cd luarocks-3.10.0 && ./configure) && (cd luarocks-3.10.0 && make) && (cd luarocks-3.10.0 && sudo make install)")
        print("----DONE----")
    end

    if not isModuleInstalled("lsqlite3") and not isModuleInstalled("ssl.https") and not isModuleInstalled("toml") then
        installModules()
    end
end

return init