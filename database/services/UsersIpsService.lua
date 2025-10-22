
UsersIpsService = {}

function UsersIpsService:getAllIps()
    if not self.beammpid then return {} end
    return DatabaseManager:withConnection(function()
        return DatabaseManager:getAllClassByBeammpId(UserIp, self.beammpid) or {}
    end)
end

function UsersIpsService:banip(ip)
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return false end
    
    for _, value in ipairs(ips) do
        if value.ip == ip then
            value.is_banned = true
            local result = DatabaseManager:save(value, false)
            return result
        end
    end
    return false
end

function UsersIpsService:banAllIps()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return 0 end
    
    local count = 0
    for _, value in ipairs(ips) do
        if value.is_banned == 0 then
            count = count + 1
            value.is_banned = true
            DatabaseManager:save(value, false)
        end
    end
    return count
end

function UsersIpsService:unbanAllIps()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return 0 end
    
    local count = 0
    for _, value in ipairs(ips) do
        if value.is_banned == 1 then
            count = count + 1
            value.is_banned = false
            DatabaseManager:save(value, true)
        end
    end
    return count
end

function UsersIpsService:isIpBanned()
    local ips = self:getAllIps()
    if not ips or type(ips) ~= "table" then return false end
    
    for _, value in ipairs(ips) do
        if value.is_banned == 1 then
            return true
        end
    end
    return false
end

return UsersIpsService