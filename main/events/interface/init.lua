local interface = require("main.client.initInterface")

local init = {}
---@param managers managers
function init.new(managers)

    local lastCallTime = {}
    local cooldown = 2 -- Cooldown period in seconds
    function initInterface(id, offset)
        local currentTime = os.time()

        if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
            print("player requested interface initialization")
            lastCallTime[id] = currentTime
            interface.init(id, managers, offset)
        end
    end
    MP.RegisterEvent("initInterface", "initInterface")

end




return init