local interface = require("main.client.initInterface")
local interfaceUtils = require("main.client.interfaceUtils")
local search = {}
---@param managers managers
function search.new(managers)

    local lastCallTime = {}
    function searchPlayer(id, search)
        local searchResults = managers.dbManager:withConnection(function()
            return managers.dbManager:likeSearchUserWithRoles(search, managers.permManager)
        end)
        interfaceUtils.sendNothing(id, "NKResetSearch", "")
        MP.Sleep(20) --need to test if it lag
        for i, v in pairs(searchResults) do
            interfaceUtils.sendPlayer(id, managers.dbManager, managers.permManager, managers.cfgManager, v.beammpid)
        end
    end
    MP.RegisterEvent("searchPlayer", "searchPlayer")

end



return search