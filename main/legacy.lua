


local legacy = {}

function legacy.importOldData()

    local path = Utils.script_path() .. "data/users/"

    local files = FS.ListFiles(path)

    for index, value in ipairs(files) do

        local file = io.open(path .. value, "r")
        local content = file:read("*all")
        file:close()
        local data = Utils.JsonDecode(content)

        -- register.register(data.beammpid, data.name, permManager, data.ip, msgManager, false)

        local usersService = UsersService.new(data.beammpid)

        local newUser = usersService:getUser()
        local roles = PermissionsManager:getDefaultsRoles()

        if newUser == nil then
            DatabaseManager:save(User.new(data.beammpid, data.name))
            for _, role in pairs(roles) do
                PermissionsManager:assignRole(role.roleName, data.beammpid)
            end

            local statusService = StatusService.new(data.beammpid)
            local usersIpsService = UsersIpsService.new(data.beammpid)


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
        end
        Utils.nkprint("Importing user: " .. data.name .. " (" .. data.beammpid .. ")", "info")

        -- for key, object in pairs(data) do
        --     print(key .. " -> ", object)
        -- end
    end
end

return legacy