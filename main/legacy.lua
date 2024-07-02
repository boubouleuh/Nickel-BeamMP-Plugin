

local utils = require("utils.misc")
local UsersService = require("database.services.UsersService")

local register = require("main.registerPlayer")

local StatusService = require("database.services.StatusService")

local UsersIpsService = require("database.services.UsersIpsService")


local legacy = {}

function legacy.importOldData(managers)

    local dbManager = managers.dbManager

    local permManager = managers.permManager

    local msgManager = managers.msgManager



    local path = utils.script_path() .. "data/users/"

    local files = FS.ListFiles(path)

    print(files)
    for index, value in ipairs(files) do

        local file = io.open(path .. value, "r")
        local content = file:read("*all")
        file:close()
        local data = Util.JsonDecode(content)

        register.register(data.beammpid, data.name, permManager, data.ip, msgManager, false)

        local statusService = StatusService.new(data.beammpid, dbManager)
        local usersService = UsersService.new(data.beammpid, dbManager)
        local usersIpsService = UsersIpsService.new(data.beammpid, dbManager)


        if data.banned.bool then
            statusService:createStatus("isbanned", data.banned.reason)
        end

        if data.tempbanned.bool then
            statusService:createStatus("istempbanned", data.tempbanned.reason, data.tempbanned.time)
        end


        if data.muted.bool then
            statusService:createStatus("ismuted", data.muted.reason)
        end

        if data.tempmuted.bool then
            statusService:createStatus("istempmuted", data.tempmuted.reason, data.tempmuted.time)
        end

        usersService:setWhitelisted(data.whitelisted)

        if data.ipbanned.bool then
            usersIpsService:banip(data.ip)
        end

        for key, object in pairs(data) do
            print(key .. " -> ", object)
        end
    end
end

return legacy