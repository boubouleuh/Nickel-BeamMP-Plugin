local user = require("objects.User")
local userIps = require("objects.UserIps")
local userStatus = require("objects.UserStatus")
local userRole = require("objects.UserRole")
local utils = require("utils.misc")
local StatusService = require("database.services.StatusService")

local registerPlayer = {}

function registerPlayer.register(beammpid, name, permManager, ip, msgManager, isguest)

    print("Problem can happen here in the register function : ", beammpid, name, ip)
    local cfgManager = msgManager.configManager

    -- Insérer ou mettre à jour un utilisateur
    if not isguest then
        local newUser = user.new(beammpid, name)
        permManager.dbManager:openConnection()
        local ipClass = permManager.dbManager:getClassByBeammpId(userIps, beammpid)
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

        permManager.dbManager:save(newUser)

        --Check status

        local statusService = StatusService.new(beammpid, permManager.dbManager)
        if statusService:checkStatus("isbanned") then
            return statusService:getStatus("isbanned").reason
        elseif statusService:checkStatus("istempbanned") then
            if statusService:checkStatusTime("istempbanned") then
                return statusService:getStatus("istempbanned").reason
            else
                statusService:removeStatus("istempbanned")
            end
        end
  

        permManager.dbManager:openConnection()
        local entries = permManager.dbManager:getAllEntry(userIps, {{"beammpid", beammpid}})
        permManager.dbManager:closeConnection()
        for _, entry in pairs(entries) do
            if entry.is_banned == 1 then
                return "REASON" --TODO ADD REASON ?
            end
        end
    elseif isguest and not cfgManager:GetSetting("conditions").guest then
        return msgManager:GetMessage(-1, "conditions.guest_not_allowed")
    end

end

return registerPlayer