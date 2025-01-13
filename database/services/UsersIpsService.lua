
local new = require("objects.New")

local userIp = require("objects.UserIp")


local Service = {}



function Service.new(beammpid, dbManager)
    local self = {}
    self.dbManager = dbManager  -- You can set this to a specific value if needed
    self.beammpid = beammpid
    return new._object(Service, self)
end
  

function Service:getAllIps()
    self.dbManager:openConnection()
    local ips = self.dbManager:getAllClassByBeammpId(userIp, self.beammpid)
    self.dbManager:closeConnection()
    return ips
end

function Service:banip(ip)
    local ips = self:getAllIps()
    for _, value in ipairs(ips) do
        if value.ip == ip then
            value.is_banned = true
            local result = self.dbManager:save(value, true)
            return result
        end
    end
end

function Service:banAllIps()
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


function Service:unbanAllIps()
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

function Service:isIpBanned()
    local ips = self:getAllIps()
    for _, value in ipairs(ips) do
        if value.is_banned == 1 then
            return true
        end
    end
    return false
end

return Service