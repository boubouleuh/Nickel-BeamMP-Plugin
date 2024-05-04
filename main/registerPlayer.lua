local user = require("objects.User")
local userIps = require("objects.UserIps")
local userStatus = require("objects.UserStatus")
local userRole = require("objects.UserRole")
local utils = require("utils.misc")

local registerPlayer = {}

function registerPlayer.register(beammpid, name, permManager, ip)

    print("Problem can happen here in the register function : ", beammpid, name, ip)
    
    -- Insérer ou mettre à jour un utilisateur
    local newUser = user.new(beammpid, name)
    permManager.dbManager:openConnection()
    local ipClass = permManager.dbManager:getClassByBeammpId(userIps, beammpid)

    local userStatusClass = permManager.dbManager:getClassByBeammpId(userStatus, beammpid)
    permManager.dbManager:closeConnection()

    if userStatusClass == nil then
        local newUserStatus = userStatus.new(beammpid)
        permManager.dbManager:save(newUserStatus)
    end
    permManager.dbManager:openConnection()
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
        local newUserIp = userIps.new(beammpid, ip)
        permManager.dbManager:save(newUserIp)
    end
    print(newUser)

    permManager.dbManager:save(newUser)

    --Check status
    if userStatusClass ~= nil then
        print("STATUS = ", userStatusClass)
        if userStatusClass.status_type == "isbanned" and userStatusClass.is_status_value == 1 then
            print("IT GO IN BRO")
            return userStatusClass.reason

        elseif userStatusClass.status_type == "istempbanned" and userStatusClass.is_status_value == 1 then
            if userStatusClass.time <= os.time() then
                return userStatusClass.reason
            else
                userStatusClass.status_type = ""
                userStatusClass.status_value = false
                permManager.dbManager:save(userStatusClass)
            end
        end
    end

    permManager.dbManager:openConnection()
    local entries = permManager.dbManager:getAllEntry(userIps, {{"beammpid", beammpid}})
    permManager.dbManager:closeConnection()
    for _, entry in pairs(entries) do
        print("ENTRY=", entry)
        if entry.is_banned == 1 then
            return "REASON" --TODO ADD REASON ?
        end
    end


end

return registerPlayer