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

function registerPlayer.register(beammpid, name, permManager, ip, msgManager, isguest)

    print("Problem can happen here in the register function : ", beammpid, name, ip)
    local cfgManager = msgManager.configManager

    -- Insérer ou mettre à jour un utilisateur
    if not isguest then

        online.savePlayerAvatarImg(name, 40)

        local usersService = UsersService.new(beammpid, permManager.dbManager)

        local newUser = usersService:getUser()
        if usersService:getUser() == nil then
            newUser = user.new(beammpid, name)
        end

        permManager.dbManager:openConnection()
        local ipClass = permManager.dbManager:getClassByBeammpId(userIp, beammpid)
        local userRoleClass = permManager.dbManager:getClassByBeammpId(userRole, beammpid)
        permManager.dbManager:closeConnection()

        local tab1 = {}

        local roles = permManager:getDefaultsRoles()
        for role in pairs(roles) do
            tab1[role] = role

        end

        local default = false
        if userRoleClass ~= nil then
            for role in pairs(userRoleClass) do
                if tab1[role.roleID] == nil then
                    default = true
                end
            end
        end
        if default or userRoleClass == nil then

            for _, role in pairs(roles) do
                print(role.roleName)
                permManager:assignRole(role.roleName, beammpid)
            end
        end


        if ipClass ~= nil then

            ipClass.ip = ip
            ipClass.ip_id = nil
            permManager.dbManager:save(ipClass, false)

        else
            local newUserIp = userIp.new(beammpid, ip)
            permManager.dbManager:save(newUserIp)
        end

        permManager.dbManager:save(newUser)



        if cfgManager:GetSetting("conditions").whitelist then
            if not usersService:isWhitelisted() then
                return "You are not whitelisted"
            end
        end


        --Check status

    
        local statusService = StatusService.new(beammpid, permManager.dbManager)

        -- Vérifier les statuts de bannissement
        local bannedStatuses = statusService:getStatus("isbanned")
        if #bannedStatuses > 0 then
            for _, status in ipairs(bannedStatuses) do
                if status.is_status_value == 1 then
                    return status.reason
                end
            end
        end
        
        -- Vérifier les statuts de bannissement temporaire
        local tempBannedStatuses = statusService:getStatus("istempbanned")
        if #tempBannedStatuses > 0 then
            for _, status in ipairs(tempBannedStatuses) do
                if statusService:checkStatusTime("istempbanned") then
                    return status.reason
                else
                    statusService:removeStatus("istempbanned")
                end
            end
        end
  

        
        local usersIpsService = UsersIpsService.new(beammpid, permManager.dbManager)

        if usersIpsService:isIpBanned() then
            return "REASON" --TODO ADD REASON ?
        end

    elseif isguest and not cfgManager:GetSetting("conditions").guest then
        return msgManager:GetMessage(-1, "conditions.guest_not_allowed")
    end


end

return registerPlayer