
UsersIpsService = {}

function UsersIpsService.new(beammpid, dbManager)
    local self = {
        dbManager = dbManager,
        beammpid = beammpid
    }
    setmetatable(self, { __index = UsersIpsService })
    return self
end
  

function UsersIpsService:getAllIps()
    return self.dbManager:withConnection(function()
        return self.dbManager:getAllClassByBeammpId(UserIp, self.beammpid)
    end)
end

function UsersIpsService:banip(ip)
    local ips = self:getAllIps()
    for _, value in ipairs(ips) do
        if value.ip == ip then
            value.is_banned = true
            local result = self.dbManager:save(value, true)
            return result
        end
    end
end

function UsersIpsService:banAllIps()
    local ips = self:getAllIps()
    local count = 0
    for _, value in ipairs(ips) do
        if value.is_banned == 0 then
            count = count + 1
            value.is_banned = true
            self.dbManager:save(value, true)
        end
    

    end
    return count
end


function UsersIpsService:unbanAllIps()
    local ips = self:getAllIps()
    local count = 0
    for _, value in ipairs(ips) do

        if value.is_banned == 1 then
            count = count + 1
            value.is_banned = false
            self.dbManager:save(value, true)
        end

    end
    return count
end

function UsersIpsService:isIpBanned()
    local ips = self:getAllIps()
    for _, value in ipairs(ips) do
        if value.is_banned == 1 then
            return true
        end
    end
    return false
end

return UsersIpsService