local lastCallTime = {}
local cooldown = 2

return Event(function (id, offset)
    local currentTime = os.time()
    if lastCallTime[id] == nil or currentTime - lastCallTime[id] >= cooldown then
        lastCallTime[id] = currentTime
        
        InterfaceManager.init(id, offset)
    end
end)

