local interface = require("main.client.initInterface")
local utils = require("utils.misc")
local lastCallTime = {}
local cooldown = 2
---@param managers managers
return function (id, offset, managers)

    local currentTime = os.time()
    if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
        lastCallTime[id] = currentTime
        -- utils.RunAsync(interface.init, 50, id, managers, offset)
        interface.init(id, managers, offset)
    end

end

