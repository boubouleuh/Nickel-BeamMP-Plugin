local user = require("objects.User")
local userIps = require("objects.UserIps")
local userStatus = require("objects.UserStatus")
local userRole = require("objects.UserRole")
local registerPlayer = {}

function registerPlayer.register(beammpid, name, permManager, ip)

    local dbManager = permManager.dbManager
    -- Insérer ou mettre à jour un utilisateur
    local newUser = user.new(beammpid, name)

    local ipClass = dbManager:getClassByBeammpId(userIps, beammpid)

    local userStatusClass = dbManager:getClassByBeammpId(userStatus, beammpid)

    if userStatusClass == nil then
        local newUserStatus = userStatus.new(beammpid)
        dbManager:save(newUserStatus)
    end
    local userRoleClass = dbManager:getClassByBeammpId(userRole, beammpid)

    print(userRoleClass)

    local tab1 = {}

    local roles = permManager:getDefaultsRoles()
    for role in pairs(roles) do
        tab1[role] = role

    end

    local default = false
    for role in pairs(userRoleClass) do
        if tab1[role.roleID] == nil then
            default = true
        end
    end

    if default then

        for _, role in pairs(roles) do
            print(role.roleName)
            permManager:assignRole(role.roleName, beammpid)
        end
    end


    if ipClass ~= nil then

        ipClass:addIp(ip)
        dbManager:save(ipClass)
  
    else 
        local newUserIp = userIps.new(beammpid, ip)
        dbManager:save(newUserIp)
    end
    print(newUser)
    dbManager:save(newUser)

end

return registerPlayer