local utils = require("utils.misc")

local init = {}

-- DO NOT USE NKPRINT DEBUG HERE !! OR IT WILL BREAK BECAUSE CONFIG ISNT GENERATED YET
local function initialize()
    -- Function to check if LuaRocks is installed
    local function isLuaRocksInstalled()
        local status = os.execute("luarocks --version > /dev/null 2>&1")
        return status
    end
    
    local function isModuleInstalled(moduleName)
        local success, module = pcall(require, moduleName)
        return success
    end

    local hasLsqlite3 = isModuleInstalled("lsqlite3")
    local hasToml = isModuleInstalled("toml")
    
    if hasLsqlite3 and hasToml then
        return
    end
    
    utils.nkprint("You dont have the needed modules, please run " .. utils.script_path() .. "modules.sh", "error")
    exit()
end

init.initialize = initialize

return init