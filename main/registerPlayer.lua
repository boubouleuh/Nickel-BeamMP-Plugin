local user = require("objects.User")
local userIps = require("objects.UserIps")
local userStatus = require("objects.UserStatus")
local userRole = require("objects.UserRole")
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

        ipClass:addIp(ip)
        permManager.dbManager:save(ipClass)
  
    else 
        local newUserIp = userIps.new(beammpid, ip)
        permManager.dbManager:save(newUserIp)
    end
    print(newUser)

    permManager.dbManager:save(newUser)

end

return registerPlayer