local user = require("objects.User")
local userIps = require("objects.UserIps")
local userStatus = require("objects.UserStatus")
local registerPlayer = {}

function registerPlayer.register(beammpid, name, dbManager, ip)

    -- Insérer ou mettre à jour un utilisateur
    local newUser = user.new(beammpid, name)
    local ipClass = dbManager:getClassByBeammpId(userIps, beammpid)

    local userStatusClass = dbManager:getClassByBeammpId(userStatus, beammpid)

    if userStatusClass == nil then
        local newUserStatus = userStatus.new(beammpid)
        dbManager:save(newUserStatus)
    end
    if ipClass ~= nil then

        ipClass:addIp(ip)
        dbManager:save(ipClass)
  
    else 
        local newUserIp = userIps.new(beammpid, ip)
        dbManager:save(newUserIp)
    end

    dbManager:save(newUser)

end

return registerPlayer