local utils = require("utils.misc")
local interfaceUtils = require("main.client.interfaceUtils")
local Infos = require("objects.Infos")

local onInit = {}
---@param managers managers
function onInit.new(managers) 
    function onPluginInit()
        local dbManager = managers.dbManager
        dbManager:openConnection()
        utils.nkprint("Thanks for using Nickel version " .. dbManager:getEntry(Infos, "infoKey", "version").infoValue , "info")
        dbManager:closeConnection()
        utils.nkprint("Please join the Nickel discord if you want to : https://discord.gg/h5P84FFw7B", "info")
    end
    MP.RegisterEvent("onInit", "onPluginInit")

end




return onInit
