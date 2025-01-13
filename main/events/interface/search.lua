local interface = require("main.client.initInterface")
local interfaceUtils = require("main.client.interfaceUtils")
local search = {}
---@param managers managers
function search.new(managers)

    local lastCallTime = {}
    function searchPlayer(id, search)
        managers.dbManager:openConnection()
        local searchResults = managers.dbManager:likeSearchUserWithRoles(search)
        managers.dbManager:closeConnection()
        interfaceUtils.sendString(id, "NKResetSearch", "")
        MP.Sleep(20) --need to test if it lag
        for i, v in pairs(searchResults) do
            interfaceUtils.sendPlayer(id, managers.dbManager, managers.permManager, v.beammpid)
        end
    end
    MP.RegisterEvent("searchPlayer", "searchPlayer")

end




return search