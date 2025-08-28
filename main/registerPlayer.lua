local user = require("objects.User")
local userIp = require("objects.UserIp")
local userStatus = require("objects.UserStatus")
local userRole = require("objects.UserRole")
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

local UsersService = require("database.services.UsersService")

local UsersIpsService = require("database.services.UsersIpsService")
local interface = require("main.client.initInterface")

local online = require("main.online")
local registerPlayer = {}

function registerPlayer.register(beammpid, name, permManager, msgManager, dbManager, cfgManager, ip, isguest)
    if not isguest then

        online.savePlayerAvatarImg(name, 40)

        local usersService = UsersService.new(beammpid, dbManager)

        local newUser = usersService:getUser()
        if usersService:getUser() == nil then
            newUser = user.new(beammpid, name)
        end

        local ipClass, userRoleClass = dbManager:withConnection(function()
            local ipClass = dbManager:getClassByBeammpId(userIp, beammpid)
            local userRoleClass = dbManager:getClassByBeammpId(userRole, beammpid)
            return ipClass, userRoleClass
        end)



        
        dbManager:save(newUser)

        
        local roles = permManager:getDefaultsRoles()
        local tab1 = {}
        for _, role in pairs(roles) do
            tab1[role.roleID] = true
        end

        local needAssignDefaults = false
        if userRoleClass ~= nil then
            for _, existing in pairs(userRoleClass) do
                if not tab1[existing.roleID] then
                    needAssignDefaults = true
                    break
                end
            end
        else
            needAssignDefaults = true
        end
        if needAssignDefaults and #roles > 0 then
            for _, role in pairs(roles) do
                permManager:assignRole(role.roleName, beammpid)
            end
        end

        
        if ipClass ~= nil and ip and ip ~= "" then
            if ipClass.ip ~= ip then
                ipClass.ip = ip
                ipClass.ip_id = nil
                dbManager:save(ipClass, false)
            end
        else
            
            local newUserIp = userIp.new(beammpid, ip)
            dbManager:save(newUserIp)
        end



        if cfgManager:GetSetting("conditions").whitelist then
            if not usersService:isWhitelisted() then
                return "You are not whitelisted"
            end
        end


        --Check status


        local statusService = StatusService.new(beammpid, dbManager)

        
        local bannedStatuses = statusService:getStatus("isbanned")
        if #bannedStatuses > 0 then
            for _, status in ipairs(bannedStatuses) do
                if status.is_status_value == 1 then
                    return status.reason
                end
            end
        end
        
        
        local tempBannedStatuses = statusService:getStatus("istempbanned")
        if #tempBannedStatuses > 0 then
            for _, status in ipairs(tempBannedStatuses) do
                if statusService:checkStatusTime("istempbanned") then
                    print("Temp ban active")
                    return status.reason
                else
                    statusService:disableStatus("istempbanned")
                end
            end
        end
  

        local usersIpsService = UsersIpsService.new(beammpid, dbManager)

        if usersIpsService:isIpBanned() then
            return "REASON" --TODO ADD REASON ?
        end

    elseif isguest and not cfgManager:GetSetting("conditions").guest then
        return msgManager:GetMessage(-1, "conditions.guest_not_allowed")
    end


end

return registerPlayer