local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")
local Infos = require("objects.Infos")

---@param managers managers
return function(managers) 
    local dbManager = managers.dbManager
    dbManager:withConnection(function()
        utils.nkprint("Thanks for using Nickel version " .. dbManager:getEntry(Infos, "infoKey", "version").infoValue , "info")
    end)
    utils.nkprint("Please join the Nickel discord if you want to : https://discord.gg/h5P84FFw7B", "info")

end

