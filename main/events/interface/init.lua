local interface = require("main.client.initInterface")
local utils = require("utils.misc")
local init = {}
---@param managers managers
function init.new(managers)

    local lastCallTime = {}
    local cooldown = 2 -- Cooldown period in seconds
    function initInterface(id, offset)
        local currentTime = os.time()
        print("current time is " .. currentTime)
        print("last call time is " .. (lastCallTime[id] or 0))
        print("cooldown is " .. cooldown)
        print("time since last call is " .. (currentTime - (lastCallTime[id] or 0)))
        print(lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown)
    
        if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
            print("player requested interface initialization")
            lastCallTime[id] = currentTime

            utils.RunAsync(interface.init, 50, id, managers, offset)

            -- interface.init(id, managers, offset)
        end
    end
    MP.RegisterEvent("initInterface", "initInterface")

end




return init